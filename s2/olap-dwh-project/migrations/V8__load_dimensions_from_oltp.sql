INSERT INTO olap.dim_category (category_id, category_name)
SELECT id, name
FROM warehouse.product_category
    ON CONFLICT (category_id) DO UPDATE SET
    category_name = EXCLUDED.category_name;

INSERT INTO olap.dim_product (product_id, product_name, category_id, category_name,
                              supplier_name, brand, unit_price, unit_of_measure)
SELECT
    pc.id,
    pc.name,
    pc.category_id,
    cat.name as category_name,
    s.organization_name as supplier_name,
    pc.attributes->>'brand' as brand,
    pc.unit_price,
    pc.unit_of_measure
FROM warehouse.product_catalog pc
    LEFT JOIN warehouse.product_category cat ON pc.category_id = cat.id
    LEFT JOIN warehouse.supplier s ON pc.supplier_id = s.id
    ON CONFLICT (product_id) DO UPDATE SET
    product_name = EXCLUDED.product_name,
                                    unit_price = EXCLUDED.unit_price,
                                    brand = EXCLUDED.brand;

INSERT INTO olap.dim_customer (customer_id, last_name, first_name, full_name,
                               email, loyalty_level)
SELECT
    id,
    last_name,
    first_name,
    CONCAT(last_name, ' ', first_name, ' ', COALESCE(patronymic, '')) as full_name,
    email,
    COALESCE(loyalty_level, 'Bronze')
FROM warehouse.customer
    ON CONFLICT (customer_id) DO UPDATE SET
    last_name = EXCLUDED.last_name,
                                     first_name = EXCLUDED.first_name,
                                     loyalty_level = EXCLUDED.loyalty_level;