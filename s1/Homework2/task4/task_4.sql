update warehouse.manager
set patronymic = 'Афанасьев'
where last_name = 'Кузнецов' and first_name = 'Олег';

select* from warehouse.manager


update warehouse.product
set stock_quantity = 1234.210
where id = 1;

select * from warehouse.product


update warehouse.customer
set last_name = 'Быков'
where last_name = 'Киров' and first_name = 'Алексей' and patronymic = 'Сергеевич'

select * from warehouse.customer