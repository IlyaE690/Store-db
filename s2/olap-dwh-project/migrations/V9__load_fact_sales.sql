INSERT INTO olap.fact_sales (
    order_id, date_id, customer_sk, product_id, category_id,
    quantity, unit_price, total_amount, net_amount, source_channel
)
SELECT
    co.id as order_id,
    20250101 as date_id,
    dc.customer_sk,
    oi.product_id,
    pc.category_id,
    oi.quantity,
    pc.unit_price,
    oi.quantity * pc.unit_price as total_amount,
    oi.quantity * pc.unit_price as net_amount,
    COALESCE(co.order_metadata->>'source', 'unknown') as source_channel
FROM warehouse.customer_order co
         JOIN warehouse.order_item oi ON co.id = oi.order_id
         JOIN warehouse.product_catalog pc ON oi.product_id = pc.id
         JOIN olap.dim_customer dc ON co.customer_id = dc.customer_id
WHERE NOT EXISTS (
    SELECT 1 FROM olap.fact_sales fs
    WHERE fs.order_id = co.id AND fs.product_id = oi.product_id
);

UPDATE olap.dim_customer dc
SET
    total_orders = (
        SELECT COUNT(DISTINCT order_id)
        FROM olap.fact_sales fs
        WHERE fs.customer_sk = dc.customer_sk
    ),
    total_spent = (
        SELECT COALESCE(SUM(net_amount), 0)
        FROM olap.fact_sales fs
        WHERE fs.customer_sk = dc.customer_sk
    );