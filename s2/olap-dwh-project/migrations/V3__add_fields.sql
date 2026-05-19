ALTER TABLE warehouse.customer
    ADD COLUMN loyalty_level VARCHAR(20),
ADD COLUMN preferences JSONB,
ADD COLUMN device_fingerprint VARCHAR(255);

ALTER TABLE warehouse.product_catalog
    ADD COLUMN attributes JSONB,
ADD COLUMN tags TEXT[],
ADD COLUMN price_history daterange,
ADD COLUMN full_text_search TSVECTOR;

ALTER TABLE warehouse.customer_order
    ADD COLUMN delivery_time_range tstzrange,
ADD COLUMN order_metadata JSONB,
ADD COLUMN delivery_coordinates point;

ALTER TABLE warehouse.order_item
    ADD COLUMN special_requests TEXT,
ADD COLUMN item_options JSONB, 
ADD COLUMN return_window daterange;