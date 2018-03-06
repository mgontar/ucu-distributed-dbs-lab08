#!/bin/bash


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
