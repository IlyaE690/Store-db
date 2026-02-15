ALTER TABLE warehouse.customer 
ADD COLUMN email VARCHAR(100);

ALTER TABLE warehouse.supplier 
ADD COLUMN phone VARCHAR(20);

ALTER TABLE warehouse.product 
ADD COLUMN name VARCHAR(50) NOT NULL;




