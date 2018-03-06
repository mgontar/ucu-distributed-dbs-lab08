#!/bin/bash

reset

printf "Clear previouse setup\n"

sudo docker stop $(sudo docker ps -a -q)
sudo docker rm $(sudo docker ps -a -q)
sudo docker network rm $(sudo docker network ls -q -f type=custom)

# Task 1: init
printf "Task 1: init replication cluster\n"

sudo docker pull cassandra
sudo docker network create csn-net

sudo docker run -v /home/mgontar/dev/lab8/data:/root/data \
-d --name csn1 -m 2g --net csn-net cassandra
sleep 2m
csn1ip="$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' csn1)"
sudo docker run -v /home/mgontar/dev/lab8/data:/root/data \
-d --name csn2 --net csn-net -m 2g -e CASSANDRA_SEEDS=$csn1ip cassandra
sleep 2m
sudo docker run -v /home/mgontar/dev/lab8/data:/root/data \
-d --name csn3 --net csn-net -m 2g -e CASSANDRA_SEEDS=$csn1ip cassandra
sleep 2m

# Task 2: check
printf "Task 2: check cluster with nodetool status\n"
sudo docker exec -i -t csn1 nodetool status

# Task 3: create 3 keyspaces
printf "Task 3: create 3 keyspaces\n"

sudo docker exec -i -t csn1 cqlsh -e "CREATE KEYSPACE \"ksproduct\" 
WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };"
sudo docker exec -i -t csn1 cqlsh -e "CREATE KEYSPACE \"kscustomer\" 
WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 2 };"
sudo docker exec -i -t csn1 cqlsh -e "CREATE KEYSPACE \"ksorder\" 
WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 3 };"

# Task 4: in each keyspace create a table
printf "Task 4: in each keyspace create a table\n"
sudo docker exec -i -t csn1 cqlsh -e "CREATE TABLE ksproduct.products (id UUID, category text, model text, producer text, 
price double, properties map<text,text>, PRIMARY KEY(id, category));"
sudo docker exec -i -t csn1 cqlsh -e "DESCRIBE ksproduct.products;"
sudo docker exec -i -t csn1 cqlsh -e "CREATE TABLE kscustomer.customers (id UUID, name text, PRIMARY KEY (id, name));"
sudo docker exec -i -t csn1 cqlsh -e "DESCRIBE kscustomer.customers;"
sudo docker exec -i -t csn1 cqlsh -e "CREATE TABLE ksorder.orders (id UUID, customer UUID, date timestamp, cost double, 
items list<frozen<tuple<UUID, int, double>>>, PRIMARY KEY (id, customer));"
sudo docker exec -i -t csn1 cqlsh -e "DESCRIBE ksorder.orders;"

# Task 5: write/read with the tables
printf "Task 5: write/read with the tables\n"
sudo docker exec -i -t csn2 cqlsh -e "COPY ksproduct.products (id, category, model, producer, price, properties) 
FROM '/root/data/products.csv' WITH DELIMITER='|' AND HEADER=TRUE;"
sudo docker exec -i -t csn2 cqlsh -e "SELECT * FROM ksproduct.products;"
sudo docker exec -i -t csn1 cqlsh -e "COPY kscustomer.customers (id, name) 
FROM '/root/data/customers.csv' WITH DELIMITER='|' AND HEADER=TRUE;"
sudo docker exec -i -t csn1 cqlsh -e "SELECT * FROM kscustomer.customers;"
sudo docker exec -i -t csn3 cqlsh -e "COPY ksorder.orders (id, customer, date, cost, items) 
FROM '/root/data/orders.csv' WITH DELIMITER='|' AND HEADER=TRUE;"
sudo docker exec -i -t csn3 cqlsh -e "SELECT * FROM ksorder.orders;"


# Task 6: check data distribution
printf "Task 6: check data distribution\n"
printf "Distribution for ksproduct\n"
sudo docker exec -i -t csn1 nodetool status ksproduct
printf "Distribution for kscustomer\n"
sudo docker exec -i -t csn1 nodetool status kscustomer
printf "Distribution for ksorder\n"
sudo docker exec -i -t csn1 nodetool status ksorder

# Task 7: check distribution of certain records
printf "Task 7: check distribution of certain records\n"
printf "Distribution for ksproduct.products record\n"
sudo docker exec -i -t csn1 nodetool getendpoints ksproduct products '861BE045-015C-1462-F203-BFF8C5929622'
printf "Distribution for kscustomer.customers record\n"
sudo docker exec -i -t csn1 nodetool getendpoints kscustomer customers '38e3be9f-b8a3-40a6-a974-7732ec45bff8'
printf "Distribution for ksorder.orders record\n"
sudo docker exec -i -t csn1 nodetool getendpoints ksorder orders 'c4f5c3cc-0a62-436b-ba7c-b1f5371ed6e9'
