insert into warehouse.customer(last_name, first_name, patronymic, email)
values('Киров', 'Алексей', 'Сергеевич', 'krv_as@gmail.com'),
		('Леонтьева', 'Дарья', 'Алексеевна', 'lv_dashunchik@gmail.com');

insert into warehouse.manager(last_name, first_name, gender)
values('Кузнецов','Олег','M');

SELECT * from warehouse.manager;

insert into warehouse.warehouse(address, manager_id)
values('г. Казань, ул. Кремлёвская, д.35', 1);

SELECT * from warehouse.warehouse; 

insert into warehouse.supplier(organization_name, phone)
values ('ООО "Морковка"', '89197245392')

SELECT * from warehouse.supplier; 

insert into warehouse.product_category(name)
values ('Овощи');

SELECT * from warehouse.product_category; 

insert into warehouse.product(category_id, unit_price, unit_of_measure, supplier_id,
warehouse_id, name)
values(2, 27.00, 'кг', 1, 1, 'Морковь')

SELECT * from warehouse.product;