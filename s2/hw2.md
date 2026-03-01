-- Запрос 1: 
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM customer
WHERE loyalty_level = 'Platinum';

![img.png](images/img.png)

CREATE INDEX idx_customer_loyalty_btree ON customer(loyalty_level);

![img_1.png](images/img_1.png)

CREATE INDEX idx_hash ON customer USING HASH(loyalty_level);

![img_2.png](images/img_2.png)





-- Запрос 2: 
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM product_catalog
WHERE unit_price > 20000;

![img_3.png](images/img_3.png)

CREATE INDEX idx_btree ON product_catalog(unit_price);

![img_4.png](images/img_4.png)

CREATE INDEX idx_hash ON product_catalog USING HASH(unit_price);
hash индекс эффективно поддерживает только "="

![img_7.png](images/img_7.png)



-- Запрос 3: 
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM customer
WHERE email LIKE 'сергей%';

![img_5.png](images/img_5.png)

CREATE INDEX idx_btree ON customer(email);

Индекс не был использован
![img_6.png](images/img_6.png)

CREATE INDEX idx_hash ON customer USING HASH(email);
hash индекс эффективно поддерживает только "="

![img_8.png](images/img_8.png)





-- Запрос 4: 
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM customer
WHERE email LIKE '%gmail.com';

![img_9.png](images/img_9.png)


CREATE INDEX idx_btree ON customer (email);
индекс не был использован, так как btree не эффективен для %LIKE

![img_10.png](images/img_10.png)

CREATE INDEX idx_hash ON customer USING HASH(email);
hash индекс эффективен только для "="

![img_11.png](images/img_11.png)




-- Запрос 5Ж
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM customer 
WHERE loyalty_level IN ('Gold', 'Platinum');

![img_12.png](images/img_12.png)


CREATE INDEX idx_btree ON customer (loyalty_level);

![img_13.png](images/img_13.png)


CREATE INDEX idx_hash ON customer USING HASH(loyalty_level);

![img_14.png](images/img_14.png)





-- Доп. запрос:
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM customer
WHERE loyalty_level IN ('Gold', 'Platinum') AND email LIKE 'а%';

![img_15.png](images/img_15.png)


CREATE INDEX idx ON customer (loyalty_level, email);


![img_16.png](images/img_16.png)