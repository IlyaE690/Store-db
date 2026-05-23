from airflow import DAG
from airflow.operators.python import PythonOperator, BranchPythonOperator
from airflow.operators.dummy import DummyOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from datetime import datetime, timedelta
import pandas as pd
from clickhouse_driver import Client

default_args = {
    'owner': 'analytics_team',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag2 = DAG(
    'analytics_build_mart',
    default_args=default_args,
    description='Build analytics data marts in ClickHouse from PostgreSQL',
    schedule_interval='0 2 * * *',
    catchup=False,
    tags=['analytics', 'clickhouse'],
)

def check_data_availability(**context):
    """Проверяем наличие данных в PostgreSQL"""
    pg_hook = PostgresHook(postgres_conn_id='postgres_default')

    result = pg_hook.get_first("SELECT COUNT(*) FROM sales_merged;")
    row_count = result[0] if result else 0

    print(f"Found {row_count} rows in PostgreSQL table 'sales_merged'")

    if row_count > 0:
        context['task_instance'].xcom_push(key='row_count', value=row_count)
        return 'create_marts'
    else:
        return 'skip_analytics'

def extract_from_postgres(**context):
    """Извлекаем данные из PostgreSQL"""
    pg_hook = PostgresHook(postgres_conn_id='postgres_default')

    df = pg_hook.get_pandas_df("""
        SELECT
            sale_id, date, customer_id, product_id,
            quantity, unit_price, total_amount, payment_method,
            name, city, loyalty_status, month, year
        FROM sales_merged
        ORDER BY date;
    """)

    print(f"Extracted {len(df)} rows from PostgreSQL")
    print(f"Date range: {df['date'].min()} to {df['date'].max()}")

    context['task_instance'].xcom_push(
        key='postgres_data',
        value=df.to_json(orient='records')
    )

    return f"Extracted {len(df)} rows from PostgreSQL"

def create_clickhouse_tables(**context):
    client = Client(
        host='clickhouse',
        port=9000,
        user='analytics_user',
        password='analytics_pass',
        database='analytics'
    )

    client.execute("""
        CREATE TABLE IF NOT EXISTS sales_by_customer (
            customer_id String,
            customer_name String,
            city String,
            loyalty_status String,
            total_revenue Float64,
            orders_count UInt32,
            avg_order_value Float64,
            last_order_date Date,
            updated_at DateTime DEFAULT now()
        ) ENGINE = ReplacingMergeTree(updated_at)
        ORDER BY customer_id
    """)

    client.execute("""
        CREATE TABLE IF NOT EXISTS sales_by_product (
            product_id String,
            total_revenue Float64,
            total_quantity UInt32,
            orders_count UInt32,
            avg_price Float64,
            updated_at DateTime DEFAULT now()
        ) ENGINE = ReplacingMergeTree(updated_at)
        ORDER BY product_id
    """)

    client.execute("""
        CREATE TABLE IF NOT EXISTS daily_sales (
            date Date,
            revenue Float64,
            orders_count UInt32,
            unique_customers UInt32,
            avg_order_value Float64,
            updated_at DateTime DEFAULT now()
        ) ENGINE = ReplacingMergeTree(updated_at)
        ORDER BY date
    """)

    client.execute("""
        CREATE TABLE IF NOT EXISTS kpi_metrics (
            metric_name String,
            metric_value Float64,
            calculated_at DateTime DEFAULT now()
        ) ENGINE = MergeTree()
        ORDER BY (metric_name, calculated_at)
    """)

    print("ClickHouse tables created successfully")
    return "Tables created"

def build_sales_by_customer(**context):
    """Строим витрину продаж по клиентам"""
    ti = context['task_instance']
    data_json = ti.xcom_pull(key='postgres_data', task_ids='extract_from_postgres')
    df = pd.read_json(data_json)

    client = Client(
        host='clickhouse',
        port=9000,
        user='analytics_user',
        password='analytics_pass',
        database='analytics'
    )

    customer_stats = df.groupby(['customer_id', 'name', 'city', 'loyalty_status']).agg({
        'total_amount': ['sum', 'mean', 'count'],
        'date': 'max'
    }).round(2)

    customer_stats.columns = ['total_revenue', 'avg_order_value', 'orders_count', 'last_order_date']
    customer_stats = customer_stats.reset_index()

    for _, row in customer_stats.iterrows():
        client.execute("""
            INSERT INTO sales_by_customer
            (customer_id, customer_name, city, loyalty_status,
             total_revenue, orders_count, avg_order_value, last_order_date)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, [
            row['customer_id'], row['name'], row['city'], row['loyalty_status'],
            row['total_revenue'], int(row['orders_count']), row['avg_order_value'],
            row['last_order_date'].strftime('%Y-%m-%d')
        ])

    result = client.execute("SELECT count() FROM sales_by_customer")
    print(f"Built sales_by_customer: {result[0][0]} customers")

    return f"Sales by customer built: {len(customer_stats)} rows"

def build_sales_by_product(**context):
    """Строим витрину продаж по продуктам"""
    ti = context['task_instance']
    data_json = ti.xcom_pull(key='postgres_data', task_ids='extract_from_postgres')
    df = pd.read_json(data_json)

    client = Client(
        host='clickhouse',
        port=9000,
        user='analytics_user',
        password='analytics_pass',
        database='analytics'
    )

    product_stats = df.groupby('product_id').agg({
        'total_amount': ['sum', 'count'],
        'quantity': 'sum',
        'unit_price': 'mean'
    }).round(2)

    product_stats.columns = ['total_revenue', 'orders_count', 'total_quantity', 'avg_price']
    product_stats = product_stats.reset_index()

    for _, row in product_stats.iterrows():
        client.execute("""
            INSERT INTO sales_by_product
            (product_id, total_revenue, total_quantity, orders_count, avg_price)
            VALUES (%s, %s, %s, %s, %s)
        """, [
            row['product_id'], row['total_revenue'], int(row['total_quantity']),
            int(row['orders_count']), row['avg_price']
        ])

    result = client.execute("SELECT count() FROM sales_by_product")
    print(f"Built sales_by_product: {result[0][0]} products")

    return f"Sales by product built: {len(product_stats)} rows"

def build_daily_sales(**context):
    """Строим витрину дневных продаж"""
    ti = context['task_instance']
    data_json = ti.xcom_pull(key='postgres_data', task_ids='extract_from_postgres')
    df = pd.read_json(data_json)

    client = Client(
        host='clickhouse',
        port=9000,
        user='analytics_user',
        password='analytics_pass',
        database='analytics'
    )

    daily_stats = df.groupby('date').agg({
        'total_amount': ['sum', 'mean', 'count'],
        'customer_id': 'nunique'
    }).round(2)

    daily_stats.columns = ['revenue', 'avg_order_value', 'orders_count', 'unique_customers']
    daily_stats = daily_stats.reset_index()

    for _, row in daily_stats.iterrows():
        client.execute("""
            INSERT INTO daily_sales
            (date, revenue, orders_count, unique_customers, avg_order_value)
            VALUES (%s, %s, %s, %s, %s)
        """, [
            row['date'].strftime('%Y-%m-%d'), row['revenue'], int(row['orders_count']),
            int(row['unique_customers']), row['avg_order_value']
        ])

    result = client.execute("SELECT count() FROM daily_sales")
    print(f"Built daily_sales: {result[0][0]} days")

    return f"Daily sales built: {len(daily_stats)} rows"

def build_kpi_metrics(**context):
    """Строим KPI метрики"""
    ti = context['task_instance']
    data_json = ti.xcom_pull(key='postgres_data', task_ids='extract_from_postgres')
    df = pd.read_json(data_json)

    client = Client(
        host='clickhouse',
        port=9000,
        user='analytics_user',
        password='analytics_pass',
        database='analytics'
    )

    client.execute("TRUNCATE TABLE kpi_metrics;")

    metrics = {
        'total_revenue': float(df['total_amount'].sum()),
        'total_orders': len(df),
        'avg_order_value': float(df['total_amount'].mean()),
        'unique_customers': df['customer_id'].nunique(),
        'repeat_customers': len(df[df.groupby('customer_id')['customer_id'].transform('count') > 1]['customer_id'].unique()),
        'repeat_rate': round(len(df[df.groupby('customer_id')['customer_id'].transform('count') > 1]['customer_id'].unique()) / df['customer_id'].nunique() * 100, 2),
        'credit_card_usage': round(len(df[df['payment_method'] == 'Credit Card']) / len(df) * 100, 2),
        'avg_daily_revenue': float(df.groupby('date')['total_amount'].sum().mean()),
        'total_quantity': int(df['quantity'].sum())
    }

    for name, value in metrics.items():
        client.execute("""
            INSERT INTO kpi_metrics (metric_name, metric_value)
            VALUES (%s, %s)
        """, [name, value])

    print("KPI Metrics:")
    for name, value in metrics.items():
        print(f"   {name}: {value}")

    return "KPI metrics built"

def skip_analytics(**context):
    print("No data available in PostgreSQL. Skipping analytics.")
    return "Analytics skipped"

def final_notification(**context):
    print("=" * 50)
    print("All analytics marts built successfully in ClickHouse!")
    print("=" * 50)
    return "Analytics completed"

task_check_data = BranchPythonOperator(
    task_id='check_data',
    python_callable=check_data_availability,
    dag=dag2,
)

task_extract = PythonOperator(
    task_id='extract_from_postgres',
    python_callable=extract_from_postgres,
    dag=dag2,
)

task_create_marts = DummyOperator(
    task_id='create_marts',
    dag=dag2,
)

task_skip = PythonOperator(
    task_id='skip_analytics',
    python_callable=skip_analytics,
    dag=dag2,
)

task_create_tables = PythonOperator(
    task_id='create_clickhouse_tables',
    python_callable=create_clickhouse_tables,
    dag=dag2,
)

task_load_customers = PythonOperator(
    task_id='build_sales_by_customer',
    python_callable=build_sales_by_customer,
    dag=dag2,
)

task_load_products = PythonOperator(
    task_id='build_sales_by_product',
    python_callable=build_sales_by_product,
    dag=dag2,
)

task_load_daily = PythonOperator(
    task_id='build_daily_sales',
    python_callable=build_daily_sales,
    dag=dag2,
)

task_load_kpi = PythonOperator(
    task_id='build_kpi_metrics',
    python_callable=build_kpi_metrics,
    dag=dag2,
)

task_finish = PythonOperator(
    task_id='final_notification',
    python_callable=final_notification,
    trigger_rule='none_failed',
    dag=dag2,
)

task_check_data >> [task_create_marts, task_skip]
task_create_marts >> task_extract >> task_create_tables >> [task_load_customers, task_load_products, task_load_daily] >> task_load_kpi >> task_finish
task_skip >> task_finish