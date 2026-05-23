from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from datetime import datetime, timedelta
import pandas as pd
import json
import os

default_args = {
    'owner': 'data_team',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag1 = DAG(
    'etl_load_csv_json',
    default_args=default_args,
    description='ETL: Load data from CSV and JSON to PostgreSQL',
    schedule_interval='@daily',
    catchup=False,
    tags=['etl'],
)

def extract_csv_data(**context):
    csv_path = '/opt/airflow/data/sales.csv'

    if not os.path.exists(csv_path):
        raise FileNotFoundError(f"CSV file not found: {csv_path}")

    df = pd.read_csv(csv_path)
    print(f"Loaded {len(df)} rows from CSV")
    print(f"CSV columns: {list(df.columns)}")

    context['task_instance'].xcom_push(
        key='csv_data',
        value=df.to_json(orient='records')
    )

    return f"CSV loaded: {len(df)} rows"

def extract_json_data(**context):
    json_path = '/opt/airflow/data/customers.json'

    if not os.path.exists(json_path):
        raise FileNotFoundError(f"JSON file not found: {json_path}")

    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"Loaded {len(data)} records from JSON")
    print(f"JSON keys: {list(data[0].keys()) if data else []}")

    context['task_instance'].xcom_push(
        key='json_data',
        value=json.dumps(data)
    )

    return f"JSON loaded: {len(data)} records"

def transform_data(**context):
    ti = context['task_instance']

    csv_json = ti.xcom_pull(key='csv_data', task_ids='extract_csv')
    json_str = ti.xcom_pull(key='json_data', task_ids='extract_json')

    df_sales = pd.read_json(csv_json)
    df_customers = pd.DataFrame(json.loads(json_str))

    df_sales['date'] = pd.to_datetime(df_sales['date'])
    df_sales = df_sales[df_sales['quantity'] > 0]
    df_sales = df_sales[df_sales['total_amount'] > 0]

    df_sales['month'] = df_sales['date'].dt.month
    df_sales['year'] = df_sales['date'].dt.year

    df_merged = df_sales.merge(
        df_customers[['customer_id', 'name', 'city', 'loyalty_status']],
        on='customer_id',
        how='left'
    )

    print(f"Transformed: {len(df_merged)} rows")
    print(f"Total revenue: {df_merged['total_amount'].sum():.2f}")
    print(f"Unique customers: {df_merged['customer_id'].nunique()}")
    print(f"Final columns: {list(df_merged.columns)}")

    context['task_instance'].xcom_push(
        key='transformed_data',
        value=df_merged.to_json(orient='records')
    )

    context['task_instance'].xcom_push(
        key='transform_stats',
        value={
            'rows': len(df_merged),
            'revenue': float(df_merged['total_amount'].sum()),
            'unique_customers': int(df_merged['customer_id'].nunique())
        }
    )

    return "Transformation completed"

def load_to_postgres(**context):
    ti = context['task_instance']

    data_json = ti.xcom_pull(key='transformed_data', task_ids='transform_data')
    df_final = pd.read_json(data_json)

    stats = ti.xcom_pull(key='transform_stats', task_ids='transform_data')

    pg_hook = PostgresHook(postgres_conn_id='postgres_default')

    create_table_sql = """
    CREATE TABLE IF NOT EXISTS sales_merged (
        sale_id INTEGER PRIMARY KEY,
        date DATE,
        customer_id VARCHAR(10),
        product_id VARCHAR(10),
        quantity INTEGER,
        unit_price DECIMAL(10,2),
        total_amount DECIMAL(10,2),
        payment_method VARCHAR(50),
        name VARCHAR(100),
        city VARCHAR(100),
        loyalty_status VARCHAR(50),
        month INTEGER,
        year INTEGER,
        loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """

    pg_hook.run(create_table_sql)


    from psycopg2.extras import execute_values
    import psycopg2

    conn = pg_hook.get_conn()
    cursor = conn.cursor()

    insert_sql = """
    INSERT INTO sales_merged
    (sale_id, date, customer_id, product_id, quantity, unit_price,
     total_amount, payment_method, name, city, loyalty_status, month, year)
    VALUES %s
    ON CONFLICT (sale_id) DO UPDATE SET
        total_amount = EXCLUDED.total_amount,
        quantity = EXCLUDED.quantity,
        loaded_at = CURRENT_TIMESTAMP
    """

    records = [
        (
            row['sale_id'], row['date'], row['customer_id'], row['product_id'],
            row['quantity'], row['unit_price'], row['total_amount'], row['payment_method'],
            row.get('name'), row.get('city'), row.get('loyalty_status'),
            row['month'], row['year']
        )
        for _, row in df_final.iterrows()
    ]

    execute_values(cursor, insert_sql, records, page_size=1000)
    conn.commit()

    cursor.close()
    conn.close()



    context['task_instance'].xcom_push(
        key='postgres_loaded',
        value={
            'table': 'sales_merged',
            'rows': len(df_final),
            'loaded_at': datetime.now().isoformat()
        }
    )

    return f"Loaded {len(df_final)} rows to PostgreSQL"

task_extract_csv = PythonOperator(
    task_id='extract_csv',
    python_callable=extract_csv_data,
    dag=dag1,
)

task_extract_json = PythonOperator(
    task_id='extract_json',
    python_callable=extract_json_data,
    dag=dag1,
)

task_transform = PythonOperator(
    task_id='transform_data',
    python_callable=transform_data,
    dag=dag1,
)

task_load = PythonOperator(
    task_id='load_to_postgres',
    python_callable=load_to_postgres,
    dag=dag1,
)

[task_extract_csv, task_extract_json] >> task_transform >> task_load