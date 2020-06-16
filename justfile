containerDbHost := "127.0.0.1"
containerDbPort := "9906"

webFiles := "site"
dbFiles := "sqlbin"


start:
    #!/usr/bin/env bash

    # Get most recent sql file from dbFiles
    sql_file=$(ls {{dbFiles}}/*.sql -Art | head -n1)

    if [ ! -f {{webFiles}}/config.php.original ]; then
        mv {{webFiles}}/config.php {{webFiles}}/config.php.original
        # Change config to debug, adjust db and change site to dev
        cat {{webFiles}}/config.php.original \
            | sed "s:'debug' => false:'debug' => true:" \
            | sed -E "s:'database' => '.*?':'database' => '${MYSQL_DATABASE}':" \
            | sed -E "s:'username' => '.*?':'username' => '${MYSQL_USER}':" \
            | sed -E "s:'password' => '.*?':'password' => '${MYSQL_PASSWORD}':" \
            | sed 's/localhost/db/' \
            | sed 's;'$PRODUCTION_SITE';'https://$DEV_SITE';' \
            > {{webFiles}}/config.php
    fi

    docker-compose up -d

    echo Waiting for database server to come online.
    while [[ ! $(curl --silent {{containerDbHost}}:{{containerDbPort}}; echo $? | grep --quiet -E '23') ]]; do echo -n .; sleep 1; done
    echo All good! Loading "$sql_file" now..

    # Load the most recently modified sql file in dbFiles
    # Modify email host to null to prevent accidental emails
    cat "$sql_file" \
        | sed 's/'${SMTP_HOST}'/null/' \
        | docker container exec -i "${COMPOSE_PROJECT_NAME}"_db_1 mysql -u$MYSQL_USER -p"$MYSQL_PASSWORD" $MYSQL_DATABASE
    docker container exec -it "${COMPOSE_PROJECT_NAME}"_web_1 php flarum cache:clear
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
