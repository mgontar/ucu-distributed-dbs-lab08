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


# Task 8: check strong consistency for different levels of consistency
printf "Task 8: check strong consistency for different levels of consistency\n"

printf "Disconnect node csn3\n"
sudo docker network disconnect csn-net csn3
sleep 20s
printf "Test write/read for CONSISTENCY ALL\n"
sudo docker exec -i -t csn1 cqlsh -e "CONSISTENCY ALL;"
printf "Write/read for rep factor 1\n"
sudo docker exec -i -t csn1 cqlsh -e "INSERT INTO ksproduct.products (id, category, model, producer, price) 
VALUES (6ab09bec-e68e-48d9-a5f8-97e6fb4c9be7, 'phone', 'Galaxy X1', 'Samsung', 100);"
sudo docker exec -i -t csn1 cqlsh -e "SELECT * FROM ksproduct.products;"
sudo docker exec -i -t csn1 cqlsh -e "DELETE FROM ksproduct.products 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9be7 AND category = 'phone';"
printf "Write/read for rep factor 2\n"
sudo docker exec -i -t csn1 cqlsh -e "INSERT INTO kscustomer.customers (id, name) 
VALUES (6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47, 'Rissella Ratto');"
sudo docker exec -i -t csn1 cqlsh -e "SELECT * FROM kscustomer.customers;"
sudo docker exec -i -t csn1 cqlsh -e "DELETE FROM kscustomer.customers 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47 AND name = 'Rissella Ratto';"
printf "Write/read for rep factor 3\n"
sudo docker exec -i -t csn1 cqlsh -e "INSERT INTO ksorder.orders (id, customer, date, cost, items) 
VALUES (6ab09bec-e68e-48d9-a5f8-97e6db4c9be7, 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47, '2017-10-23', 400, 
[(531F6ECA-F441-29F9-254F-9539F30CB3EE, 1, 400)]);"
sudo docker exec -i -t csn1 cqlsh -e "SELECT * FROM ksorder.orders;"
sudo docker exec -i -t csn1 cqlsh -e "DELETE FROM ksorder.orders 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6db4c9be7 AND customer = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47;"

printf "Test write/read for CONSISTENCY SERIAL\n"
sudo docker exec -i -t csn1 cqlsh -e "CONSISTENCY SERIAL;"
printf "Write/read for rep factor 1\n"
sudo docker exec -i -t csn1 cqlsh -e "INSERT INTO ksproduct.products (id, category, model, producer, price) 
VALUES (6ab09bec-e68e-48d9-a5f8-97e6fb4c9be7, 'phone', 'Galaxy X1', 'Samsung', 100);"
sudo docker exec -i -t csn1 cqlsh -e "SELECT * FROM ksproduct.products 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9be7 AND category = 'phone';"
sudo docker exec -i -t csn1 cqlsh -e "DELETE FROM ksproduct.products 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9be7 AND category = 'phone';"
printf "Write/read for rep factor 2\n"
sudo docker exec -i -t csn1 cqlsh -e "INSERT INTO kscustomer.customers (id, name) 
VALUES (6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47, 'Rissella Ratto');"
sudo docker exec -i -t csn1 cqlsh -e "SELECT * FROM kscustomer.customers 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47 AND name = 'Rissella Ratto';"
sudo docker exec -i -t csn1 cqlsh -e "DELETE FROM kscustomer.customers 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47 AND name = 'Rissella Ratto';"
printf "Write/read for rep factor 3\n"
sudo docker exec -i -t csn1 cqlsh -e "INSERT INTO ksorder.orders (id, customer, date, cost, items) 
VALUES (6ab09bec-e68e-48d9-a5f8-97e6db4c9be7, 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47, '2017-10-23', 400, 
[(531F6ECA-F441-29F9-254F-9539F30CB3EE, 1, 400)]);"
sudo docker exec -i -t csn1 cqlsh -e "SELECT * FROM ksorder.orders 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6db4c9be7 AND customer = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47;"
sudo docker exec -i -t csn1 cqlsh -e "DELETE FROM ksorder.orders 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6db4c9be7 AND customer = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47;"

printf "Test write/read for CONSISTENCY QUORUM\n"
sudo docker exec -i -t csn1 cqlsh -e "CONSISTENCY QUORUM;"
printf "Write/read for rep factor 1\n"
sudo docker exec -i -t csn1 cqlsh -e "INSERT INTO ksproduct.products (id, category, model, producer, price) 
VALUES (6ab09bec-e68e-48d9-a5f8-97e6fb4c9be7, 'phone', 'Galaxy X1', 'Samsung', 100);"
sudo docker exec -i -t csn1 cqlsh -e "SELECT * FROM ksproduct.products 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9be7 AND category = 'phone';"
sudo docker exec -i -t csn1 cqlsh -e "DELETE FROM ksproduct.products 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9be7 AND category = 'phone';"
printf "Write/read for rep factor 2\n"
sudo docker exec -i -t csn1 cqlsh -e "INSERT INTO kscustomer.customers (id, name) 
VALUES (6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47, 'Rissella Ratto');"
sudo docker exec -i -t csn1 cqlsh -e "SELECT * FROM kscustomer.customers 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47 AND name = 'Rissella Ratto';"
sudo docker exec -i -t csn1 cqlsh -e "DELETE FROM kscustomer.customers 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47 AND name = 'Rissella Ratto';"
printf "Write/read for rep factor 3\n"
sudo docker exec -i -t csn1 cqlsh -e "INSERT INTO ksorder.orders (id, customer, date, cost, items) 
VALUES (6ab09bec-e68e-48d9-a5f8-97e6db4c9be7, 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47, '2017-10-23', 400, 
[(531F6ECA-F441-29F9-254F-9539F30CB3EE, 1, 400)]);"
sudo docker exec -i -t csn1 cqlsh -e "SELECT * FROM ksorder.orders 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6db4c9be7 AND customer = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47;"
sudo docker exec -i -t csn1 cqlsh -e "DELETE FROM ksorder.orders 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6db4c9be7 AND customer = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47;"

printf "Test write/read for CONSISTENCY TWO\n"
sudo docker exec -i -t csn1 cqlsh -e "CONSISTENCY TWO;"
printf "Write/read for rep factor 1\n"
sudo docker exec -i -t csn1 cqlsh -e "INSERT INTO ksproduct.products (id, category, model, producer, price) 
VALUES (6ab09bec-e68e-48d9-a5f8-97e6fb4c9be7, 'phone', 'Galaxy X1', 'Samsung', 100);"
sudo docker exec -i -t csn1 cqlsh -e "SELECT * FROM ksproduct.products 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9be7 AND category = 'phone';"
sudo docker exec -i -t csn1 cqlsh -e "DELETE FROM ksproduct.products 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9be7 AND category = 'phone';"
printf "Write/read for rep factor 2\n"
sudo docker exec -i -t csn1 cqlsh -e "INSERT INTO kscustomer.customers (id, name) 
VALUES (6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47, 'Rissella Ratto');"
sudo docker exec -i -t csn1 cqlsh -e "SELECT * FROM kscustomer.customers 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47 AND name = 'Rissella Ratto';"
sudo docker exec -i -t csn1 cqlsh -e "DELETE FROM kscustomer.customers 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47 AND name = 'Rissella Ratto';"
printf "Write/read for rep factor 3\n"
sudo docker exec -i -t csn1 cqlsh -e "INSERT INTO ksorder.orders (id, customer, date, cost, items) 
VALUES (6ab09bec-e68e-48d9-a5f8-97e6db4c9be7, 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47, '2017-10-23', 400, 
[(531F6ECA-F441-29F9-254F-9539F30CB3EE, 1, 400)]);"
sudo docker exec -i -t csn1 cqlsh -e "SELECT * FROM ksorder.orders 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6db4c9be7 AND customer = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47;"
sudo docker exec -i -t csn1 cqlsh -e "DELETE FROM ksorder.orders 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6db4c9be7 AND customer = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47;"

printf "Test write/read for CONSISTENCY ONE\n"
sudo docker exec -i -t csn1 cqlsh -e "CONSISTENCY ONE;"
printf "Write/read for rep factor 1\n"
sudo docker exec -i -t csn1 cqlsh -e "INSERT INTO ksproduct.products (id, category, model, producer, price) 
VALUES (6ab09bec-e68e-48d9-a5f8-97e6fb4c9be7, 'phone', 'Galaxy X1', 'Samsung', 100);"
sudo docker exec -i -t csn1 cqlsh -e "SELECT * FROM ksproduct.products 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9be7 AND category = 'phone';"
sudo docker exec -i -t csn1 cqlsh -e "DELETE FROM ksproduct.products 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9be7 AND category = 'phone';"
printf "Write/read for rep factor 2\n"
sudo docker exec -i -t csn1 cqlsh -e "INSERT INTO kscustomer.customers (id, name) 
VALUES (6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47, 'Rissella Ratto');"
sudo docker exec -i -t csn1 cqlsh -e "SELECT * FROM kscustomer.customers 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47 AND name = 'Rissella Ratto';"
sudo docker exec -i -t csn1 cqlsh -e "DELETE FROM kscustomer.customers 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47 AND name = 'Rissella Ratto';"
printf "Write/read for rep factor 3\n"
sudo docker exec -i -t csn1 cqlsh -e "INSERT INTO ksorder.orders (id, customer, date, cost, items) 
VALUES (6ab09bec-e68e-48d9-a5f8-97e6db4c9be7, 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47, '2017-10-23', 400, 
[(531F6ECA-F441-29F9-254F-9539F30CB3EE, 1, 400)]);"
sudo docker exec -i -t csn1 cqlsh -e "SELECT * FROM ksorder.orders 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6db4c9be7 AND customer = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47;"
sudo docker exec -i -t csn1 cqlsh -e "DELETE FROM ksorder.orders 
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6db4c9be7 AND customer = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47;"

printf "Connect node csn3\n"
sudo docker network connect csn-net csn3
sleep 20s

# Task 9: disconnect all nodes
printf "Task 9: disconnect all nodes\n"
sudo docker network disconnect csn-net csn1
sudo docker network disconnect csn-net csn2
sudo docker network disconnect csn-net csn3
sleep 20s

# Task 10: write records with the same PK on each node
printf "Task 10: write records with the same PK on each node\n"
printf "Write/read for rep factor 3 at node csn1\n"
sudo docker exec -i -t csn1 cqlsh -e "INSERT INTO ksorder.orders (id, customer, date, cost, items) 
VALUES (6ab09bec-e68e-48d9-a5f8-97e6db4c9be7, 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47, '2017-10-24', 400, 
[(531F6ECA-F441-29F9-254F-9539F30CB3EE, 1, 400)]);"
sudo docker exec -i -t csn1 cqlsh -e "SELECT * FROM ksorder.orders
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6db4c9be7 AND customer = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47;"
printf "Write/read for rep factor 3 at node csn2\n"
sudo docker exec -i -t csn2 cqlsh -e "INSERT INTO ksorder.orders (id, customer, date, cost, items) 
VALUES (6ab09bec-e68e-48d9-a5f8-97e6db4c9be7, 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47, '2017-10-25', 400, 
[(531F6ECA-F441-29F9-254F-9539F30CB3EE, 1, 400)]);"
sudo docker exec -i -t csn2 cqlsh -e "SELECT * FROM ksorder.orders
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6db4c9be7 AND customer = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47;"
printf "Write/read for rep factor 3 at node csn3\n"
sudo docker exec -i -t csn3 cqlsh -e "INSERT INTO ksorder.orders (id, customer, date, cost, items) 
VALUES (6ab09bec-e68e-48d9-a5f8-97e6db4c9be7, 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47, '2017-10-26', 400, 
[(531F6ECA-F441-29F9-254F-9539F30CB3EE, 1, 400)]);"
sudo docker exec -i -t csn3 cqlsh -e "SELECT * FROM ksorder.orders
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6db4c9be7 AND customer = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47;"

# Task 11: reconnect all nodes and check the record value
printf "Task 11: reconnect all nodes and check the record value\n"
sudo docker network connect csn-net csn1
sudo docker network connect csn-net csn2
sudo docker network connect csn-net csn3
sleep 20s
sudo docker exec -i -t csn1 cqlsh -e "SELECT * FROM ksorder.orders
WHERE id = 6ab09bec-e68e-48d9-a5f8-97e6db4c9be7 AND customer = 6ab09bec-e68e-48d9-a5f8-97e6fb4c9b47;"
