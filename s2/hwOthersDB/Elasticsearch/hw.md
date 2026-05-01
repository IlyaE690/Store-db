1) Поднимаем Elasticsearch

docker run -d --name elasticsearch-lab -p 9200:9200 -e "discovery.type=single-node" elasticsearch:7.17.22

![img.png](photo/img.png)

2) Через Postman создаем индекс с помощью ElasticSearch Postman collection.json

![img_1.png](photo/img_1.png)

3) Через Postman наполняем данными 

![img_2.png](photo/img_2.png)

![img_3.png](photo/img_3.png)

4) 4 запроса

поиск по названию

![img_4.png](photo/img_4.png)

фильтр по цене

![img_5.png](photo/img_5.png)


точное совпадение

![img_6.png](photo/img_6.png)

bool (комбинированный)

![img_7.png](photo/img_7.png)



