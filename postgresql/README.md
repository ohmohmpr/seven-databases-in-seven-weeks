docker exec -it postgresql_db_1 psql -h localhost -U postgres

docker exec -it postgresql_db_1 bash
createdb -h localhost -U postgres 7dbs
psql -h localhost -U postgres 7dbs


docker exec -it postgresql_db_1 createdb -h localhost -U postgres 7dbs

docker exec -it postgresql_db_1 psql -h localhost -U postgres -d 7dbs

cat ./script/add_event.sql | docker exec -i postgresql_db_1 psql -U postgres -d 7dbs



