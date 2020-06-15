containerDbHost := "127.0.0.1"
containerDbPort := "9906"

webFiles := "site"
dbFiles := "sqlbin"


start:
    #!/usr/bin/env bash

    # Get most recent sql file from dbFiles
    sql_file=$(ls {{dbFiles}}/*.sql -Art | head -n1)

    cp {{webFiles}}/config.php {{webFiles}}/config.php.original
    sed -i "s:'debug' => false:'debug' => true:" {{webFiles}}/config.php # change config to debug: true
    sed -i 's/localhost/db/' {{webFiles}}/config.php # change database location docker db
    sed -i 's;'$PRODUCTION_SITE';'https://$DEV_SITE';' {{webFiles}}/config.php # Change url in config

    docker-compose up -d

    echo Waiting for database server to come online.
    while [[ ! $(curl --silent {{containerDbHost}}:{{containerDbPort}}; echo $? | grep --quiet -E '23') ]]; do echo -n .; sleep 1; done
    echo All good! Loading "$sql_file" now..

    # Load the most recently modified sql file in dbFiles
    # Modify email host to null to prevent accidental emails
    cat "$sql_file" \
        | sed 's/'${SMTP_HOST}'/null/' \
        | docker container exec -i "${COMPOSE_PROJECT_NAME}"_db_1 mysql -u$MYSQL_USER -p"$MYSQL_PASSWORD" $MYSQL_DATABASE
    echo All done! Open up https://"$DEV_SITE"
enter:
    docker container exec -it "${COMPOSE_PROJECT_NAME}"_web_1 bash
stop:
    docker-compose down --volumes
    mv {{webFiles}}/config.php.original {{webFiles}}/config.php 
build:
    docker-compose build
logs:
    docker container logs -f "${COMPOSE_PROJECT_NAME}"_web_1
