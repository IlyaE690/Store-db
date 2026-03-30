![img.png](images/hw6/img.png)

![img_1.png](images/hw6/img_1.png)

![img_2.png](images/hw6/img_2.png)

![img_3.png](images/hw6/img_3.png)

![img_4.png](images/hw6/img_4.png)

![img_5.png](images/hw6/img_5.png)

![img_6.png](images/hw6/img_6.png)

1) есть ли partition pruning

Да, так как сканировалась только 1 партиция, а не все 3

2) сколько партиций участвует в плане

1 партиция

3) Используется ли индекс?

Нет, так как он не был создан.

![img_7.png](images/hw6/img_7.png)

![img_8.png](images/hw6/img_8.png)

![img_9.png](images/hw6/img_9.png)

![img_10.png](images/hw6/img_10.png)

Если индекс создан, то он будет использоваться 

** **
** **
** **

![img_11.png](images/hw6/img_11.png)

В мастер-реплике: 

![img_12.png](images/hw6/img_12.png)

В ведомых репликах:

![img_13.png](images/hw6/img_13.png)


Секционирование есть на репликах, но реплика не знает о секциях, потому что работает на уровне WAL

То есть мастер записывает в WAL изменения на уровне байтов, а реплика знает только, какие байты в каком месте диска изменить

** **
** **
** **

![img_14.png](images/hw6/img_14.png)

На мастере:

![img_15.png](images/hw6/img_15.png)

**publish_via_partition_root = OFF**

В мастере создаем родительскую таблицу и секции

![img_16.png](images/hw6/img_16.png)

Создаем публикацию:

![img_17.png](images/hw6/img_17.png)

На подписчике создаем таблицы-секции, запросы будут идти на них

![img_18.png](images/hw6/img_18.png)

Создаем подписку

![img_19.png](images/hw6/img_19.png)

Вставляем данные в публикатора

![img_20.png](images/hw6/img_20.png)

Проверяем что пришло на подписчика:

![img_21.png](images/hw6/img_21.png)

**publish_via_partition_root = ON**

Чистим таблицы, удаляем таблицы на подписчике и удаляем публикацию и подписку

Создаем публикацию

![img_22.png](images/hw6/img_22.png)

На подписчике создаем только 1 таблицу-родителя

![img_23.png](images/hw6/img_23.png)

Создаем подписку

![img_24.png](images/hw6/img_24.png)

Вставляем данные в публикатора

![img_25.png](images/hw6/img_25.png)

На подписчике:

![img_26.png](images/hw6/img_26.png)

Изменения передались через родительскую таблицу


** **
** **
** **

![img_27.png](images/hw6/img_27.png)

Поднимаем 3 контейнера (router, shard1, shard2)

Сначала настраиваем шарды

![img_28.png](images/hw6/img_28.png)

Аналогично shard2, но 101 <= id <= 200

Настраиваем роутер

Создаем серверы по именам контейнеров 

![img_29.png](images/hw6/img_29.png)

Даем права на подключение 

![img_30.png](images/hw6/img_30.png)

Создаем таблицу-роутер для маршрутизации

![img_31.png](images/hw6/img_31.png)

Привязываем таблицы из шардов как партиции

![img_32.png](images/hw6/img_32.png)

Вставляем данные через роутер

![img_33.png](images/hw6/img_33.png)


Простой запрос на все данные 

![img_34.png](images/hw6/img_34.png)


Простой запрос на шард 

![img_35.png](images/hw6/img_35.png)
