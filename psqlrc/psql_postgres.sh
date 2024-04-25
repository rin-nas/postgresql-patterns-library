# как войти без пароля (если в pg_hba.conf прописан метод peer) и подтянуть .psqlrc из своей домашней директории
sudo su - postgres -c "export PSQLRC=${HOME}/.psqlrc && psql -q"
