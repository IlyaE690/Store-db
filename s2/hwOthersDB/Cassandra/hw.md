1) 
Создан docker-compose файл

Создан Keyspace c фактором репликации 2

![img.png](photo/img.png)

2) 
Создана таблица student_grades с настроенными ключами Partition Key и Clustering Key

![img_1.png](photo/img_1.png)

Выполнена вставка данных с использованием uid()

![img_2.png](photo/img_2.png)

3) 
Найдены uid студентов

![img_3.png](photo/img_3.png)

Получены ip нод с данными 2 студентов, данные хранятся на 2 репликах 

![img_4.png](photo/img_4.png)

4) 
Пробуем выполнить поиск по предмету(не ключевому полю), выдало ошибку 

![img_5.png](photo/img_5.png)

Добавляем ALLOW FILTERING, все работает

![img_6.png](photo/img_6.png)