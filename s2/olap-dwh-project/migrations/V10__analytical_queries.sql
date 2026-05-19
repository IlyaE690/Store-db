

SELECT
    d.full_date,
    d.year,
    d.month_name,
    d.day_name,
    COUNT(DISTINCT fs.order_id) as total_orders,
    SUM(fs.quantity) as items_sold,
    SUM(fs.net_amount) as daily_revenue,
    ROUND(AVG(fs.net_amount), 2) as avg_order_value,
    COUNT(DISTINCT fs.customer_sk) as active_customers,
    LAG(SUM(fs.net_amount)) OVER (ORDER BY d.full_date) as prev_day_revenue,
    ROUND(100.0 * (SUM(fs.net_amount) - LAG(SUM(fs.net_amount)) OVER (ORDER BY d.full_date)) /
          NULLIF(LAG(SUM(fs.net_amount)) OVER (ORDER BY d.full_date), 0), 2) as revenue_change_pct
FROM olap.fact_sales fs
         JOIN olap.dim_date d ON fs.date_id = d.date_id
GROUP BY d.full_date, d.year, d.month_name, d.day_name
ORDER BY d.full_date DESC
    LIMIT 30;



SELECT
    COALESCE(dc.category_name, 'Без категории') as category_name,
    COUNT(DISTINCT fs.order_id) as orders_count,
    SUM(fs.quantity) as items_sold,
    SUM(fs.net_amount) as total_revenue,
    ROUND(100.0 * SUM(fs.net_amount) / SUM(SUM(fs.net_amount)) OVER (), 2) as revenue_share_percent,
    COUNT(DISTINCT fs.customer_sk) as unique_customers,
    ROUND(AVG(fs.net_amount), 2) as avg_order_value
FROM olap.fact_sales fs
         LEFT JOIN olap.dim_category dc ON fs.category_id = dc.category_id
GROUP BY dc.category_name
ORDER BY total_revenue DESC
    LIMIT 10;



SELECT
    dc.loyalty_level,
    COUNT(DISTINCT dc.customer_id) as total_customers,
    SUM(fs.net_amount) as total_revenue,
    ROUND(AVG(fs.net_amount), 2) as avg_revenue_per_customer,
    ROUND(AVG(dc.total_orders), 2) as avg_orders_per_customer,
    ROUND(AVG(fs.quantity), 2) as avg_items_per_order,
    ROUND(100.0 * SUM(fs.net_amount) / SUM(SUM(fs.net_amount)) OVER (), 2) as revenue_share
FROM olap.fact_sales fs
         JOIN olap.dim_customer dc ON fs.customer_sk = dc.customer_sk
GROUP BY dc.loyalty_level
ORDER BY avg_revenue_per_customer DESC;



SELECT
    dp.product_name,
    dp.brand,
    COUNT(DISTINCT fs.order_id) as times_ordered,
    SUM(fs.quantity) as total_quantity_sold,
    SUM(fs.net_amount) as total_revenue,
    COUNT(DISTINCT fs.customer_sk) as unique_buyers,
    ROUND(AVG(fs.unit_price), 2) as avg_price
FROM olap.fact_sales fs
         JOIN olap.dim_product dp ON fs.product_id = dp.product_id
GROUP BY dp.product_id, dp.product_name, dp.brand
ORDER BY total_quantity_sold DESC
    LIMIT 10;


SELECT 'Total customers' as metric, value::TEXT FROM (SELECT COUNT(*) as value FROM olap.dim_customer) t
UNION ALL
SELECT 'Total products', value::TEXT FROM (SELECT COUNT(*) as value FROM olap.dim_product) t
UNION ALL
SELECT 'Total categories', value::TEXT FROM (SELECT COUNT(*) as value FROM olap.dim_category) t
UNION ALL
SELECT 'Total sales facts', value::TEXT FROM (SELECT COUNT(*) as value FROM olap.fact_sales) t
UNION ALL
SELECT 'Total orders', value::TEXT FROM (SELECT COUNT(DISTINCT order_id) as value FROM olap.fact_sales) t
UNION ALL
SELECT 'Total revenue', COALESCE(SUM(net_amount)::TEXT, '0') FROM olap.fact_sales;