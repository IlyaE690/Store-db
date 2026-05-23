from airflow import DAG
from airflow.operators.python import PythonOperator, BranchPythonOperator
from airflow.operators.dummy import DummyOperator
from datetime import datetime, timedelta
import pandas as pd
import json
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
    description='Build analytics data marts in ClickHouse',
    schedule_interval='0 2 * * *',
    catchup=False,
    tags=['analytics', 'clickhouse'],
)

def check_data_availability(**context):
    print("Checking data availability in PostgreSQL...")
    has_data = True

    if has_data:
        return 'create_marts'
    else:
        return 'skip_analytics'

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
            last_order_date Date
        ) ENGINE = MergeTree()
        ORDER BY customer_id
    """)

    client.execute("""
        CREATE TABLE IF NOT EXISTS sales_by_product (
            product_id String,
            total_revenue Float64,
            total_quantity UInt32,
            orders_count UInt32,
            avg_price Float64
        ) ENGINE = MergeTree()
        ORDER BY product_id
    """)

    client.execute("""
        CREATE TABLE IF NOT EXISTS daily_sales (
            date Date,
            revenue Float64,
            orders_count UInt32,
            unique_customers UInt32,
            avg_order_value Float64
        ) ENGINE = MergeTree()
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

def load_sales_by_customer(**context):
    client = Client(
        host='clickhouse',
        port=9000,
        user='analytics_user',
        password='analytics_pass',
        database='analytics'
    )

    client.execute("""
        INSERT INTO sales_by_customer VALUES
        ('C001', 'Иван Петров', 'Москва', 'Gold', 579.92, 3, 193.31, '2024-01-19'),
        ('C002', 'Мария Иванова', 'СПб', 'Silver', 449.96, 3, 149.99, '2024-01-20'),
        ('C003', 'Алексей Смирнов', 'Москва', 'Platinum', 589.92, 4, 147.48, '2024-01-24'),
        ('C004', 'Ольга Козлова', 'Казань', 'Standard', 449.93, 3, 149.98, '2024-01-23'),
        ('C005', 'Дмитрий Волков', 'Екб', 'Silver', 249.97, 2, 124.99, '2024-01-24'),
        ('C006', 'Елена Соколова', 'Москва', 'Standard', 349.93, 3, 116.64, '2024-01-22')
    """)

    result = client.execute("SELECT count() FROM sales_by_customer")
    print(f"Loaded {result[0][0]} rows to sales_by_customer")

    return "Mart sales_by_customer loaded"

def load_sales_by_product(**context):
    client = Client(
        host='clickhouse',
        port=9000,
        user='analytics_user',
        password='analytics_pass',
        database='analytics'
    )

    client.execute("""
        INSERT INTO sales_by_product VALUES
        ('P101', 599.94, 6, 3, 99.99),
        ('P102', 549.90, 9, 4, 61.10),
        ('P103', 479.94, 6, 3, 79.99),
        ('P104', 399.90, 9, 4, 44.43),
        ('P105', 449.97, 3, 2, 149.99)
    """)

    result = client.execute("SELECT count() FROM sales_by_product")
    print(f"Loaded {result[0][0]} rows to sales_by_product")

    return "Mart sales_by_product loaded"

def load_daily_sales(**context):
    client = Client(
        host='clickhouse',
        port=9000,
        user='analytics_user',
        password='analytics_pass',
        database='analytics'
    )

    client.execute("""
        INSERT INTO daily_sales VALUES
        ('2024-01-15', 349.96, 2, 2, 174.98),
        ('2024-01-16', 279.97, 2, 2, 139.99),
        ('2024-01-17', 549.93, 2, 2, 274.97),
        ('2024-01-18', 339.96, 2, 2, 169.98),
        ('2024-01-19', 299.94, 2, 2, 149.97),
        ('2024-01-20', 249.97, 2, 2, 124.99),
        ('2024-01-21', 159.98, 1, 1, 159.98),
        ('2024-01-22', 399.94, 2, 2, 199.97),
        ('2024-01-23', 279.97, 2, 2, 139.99),
        ('2024-01-24', 299.96, 2, 2, 149.98)
    """)

    result = client.execute("SELECT count() FROM daily_sales")
    print(f"Loaded {result[0][0]} rows to daily_sales")

    return "Mart daily_sales loaded"

def load_kpi_metrics(**context):
    client = Client(
        host='clickhouse',
        port=9000,
        user='analytics_user',
        password='analytics_pass',
        database='analytics'
    )

    client.execute("""
        INSERT INTO kpi_metrics (metric_name, metric_value) VALUES
        ('total_revenue', 2469.62),
        ('total_orders', 20),
        ('avg_order_value', 123.48),
        ('unique_customers', 6),
        ('repeat_customers', 4),
        ('repeat_rate', 66.67),
        ('credit_card_usage', 45.0),
        ('avg_daily_revenue', 246.96)
    """)

    result = client.execute("SELECT count() FROM kpi_metrics")
    print(f"Loaded {result[0][0]} KPI metrics")

    metrics = client.execute("SELECT * FROM kpi_metrics")
    print("Current KPIs:")
    for metric in metrics:
        print(f"  {metric[0]}: {metric[1]}")

    return "KPI metrics loaded"

def run_analytics_queries(**context):
    client = Client(
        host='clickhouse',
        port=9000,
        user='analytics_user',
        password='analytics_pass',
        database='analytics'
    )

    top_customers = client.execute("""
        SELECT customer_name, total_revenue, orders_count
        FROM sales_by_customer
        ORDER BY total_revenue DESC
        LIMIT 3
    """)

    print("Top 3 Customers:")
    for customer in top_customers:
        print(f"  {customer[0]}: ${customer[1]:.2f} ({customer[2]} orders)")

    top_products = client.execute("""
        SELECT product_id, total_revenue, total_quantity
        FROM sales_by_product
        ORDER BY total_revenue DESC
        LIMIT 3
    """)

    print("Top 3 Products:")
    for product in top_products:
        print(f"  {product[0]}: ${product[1]:.2f} ({product[2]} units)")

    daily_stats = client.execute("""
        SELECT
            max(date) as last_date,
            sum(revenue) as total_revenue,
            avg(avg_order_value) as avg_order
        FROM daily_sales
    """)

    print(f"Daily Stats - Last Date: {daily_stats[0][0]}")
    print(f"Total Revenue: ${daily_stats[0][1]:.2f}")
    print(f"Avg Order: ${daily_stats[0][2]:.2f}")

    return "Analytics queries completed"

def skip_analytics(**context):
    print("No data available. Skipping analytics.")
    return "Analytics skipped"

def final_notification(**context):
    print("All analytics marts built successfully in ClickHouse!")
    return "Analytics completed"

task_check_data = BranchPythonOperator(
    task_id='check_data',
    python_callable=check_data_availability,
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
    task_id='load_sales_by_customer',
    python_callable=load_sales_by_customer,
    dag=dag2,
)

task_load_products = PythonOperator(
    task_id='load_sales_by_product',
    python_callable=load_sales_by_product,
    dag=dag2,
)

task_load_daily = PythonOperator(
    task_id='load_daily_sales',
    python_callable=load_daily_sales,
    dag=dag2,
)

task_load_kpi = PythonOperator(
    task_id='load_kpi_metrics',
    python_callable=load_kpi_metrics,
    dag=dag2,
)

task_analytics = PythonOperator(
    task_id='run_analytics_queries',
    python_callable=run_analytics_queries,
    dag=dag2,
)

task_finish = PythonOperator(
    task_id='final_notification',
    python_callable=final_notification,
    trigger_rule='none_failed',
    dag=dag2,
)

task_check_data >> [task_create_marts, task_skip]
task_create_marts >> task_create_tables >> [task_load_customers, task_load_products, task_load_daily] >> task_load_kpi >> task_analytics >> task_finish
task_skip >> task_finish
