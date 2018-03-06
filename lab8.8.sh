#!/bin/bash

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
