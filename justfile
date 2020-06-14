containerDbHost := "127.0.0.1"
containerDbPort := "9906"

webFiles := "site"

start:
    #!/usr/bin/env bash
    sed -i "s:'debug' => false:'debug' => true:" {{webFiles}}/config.php # change config to debug: true
    sed -i 's/localhost/db/' {{webFiles}}/config.php # change database location docker db
    sed -i 's;'$PRODUCTION_SITE';'https://$DEV_SITE';' {{webFiles}}/config.php # Change url in config
    sed -ie '/%{HTTPS} off/,+5d' {{webFiles}}/public/.htaccess # Hack for removing http -> https redirect
    sed -i 's/'${SMTP_HOST}'/null/' $DB_FILE # Hack to prevent emails leaking while testing

    if [ ! -f "webserver/ssl.key" ]; then just setup-ssl; fi

    docker-compose up -d

    echo Waiting for database server to come online.
    while [[ ! $(curl --silent {{containerDbHost}}:{{containerDbPort}}; echo $? | grep --quiet -E '23') ]]; do echo -n .; sleep 1; done
    echo All good! Loading database now..

    cat $DB_FILE | docker container exec -i "${COMPOSE_PROJECT_NAME}"_db_1 mysql -u$MYSQL_USER -p"$MYSQL_PASSWORD" $MYSQL_DATABASE
    echo All done! Open up https://"$DEV_SITE"
enter:
    docker container exec -it "${COMPOSE_PROJECT_NAME}"_web_1 bash
stop:
    docker-compose down --volumes
build:
    docker-compose build
logs:
    docker container logs -f ledstrainorg_web_1
setup-ssl:
    #!/usr/bin/env bash
    echo generating a self-signed cert for ${DEV_SITE}
    openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj \
        "/C=NA/ST=NA/L=NA/O=kulga/CN=${DEV_SITE}" \
        -keyout ./webserver/ssl.key -out ./webserver/ssl.crt
    chmod 644 ./webserver/ssl.*
    just build
