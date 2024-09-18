# как войти без пароля (если в pg_hba.conf прописан метод peer) и подтянуть .psqlrc из своей домашней директории?
cp -f ${HOME}/.psqlrc /tmp/.psqlrc && sudo su - postgres -c "export PSQLRC=/tmp/.psqlrc && psql -q"
