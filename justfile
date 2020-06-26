start:
    #!/usr/bin/env bash

    if [ ! -f .env ]; then
        tail -n +2 example.env > .env
        source .env
        mkdir -p ${DB_FILES} ${WEB_FILES}
        echo "No .env file found! Defaults have been loaded. Make sure ${DB_FILES} has a sql export of the forum and ${WEB_FILES} has the site files"
        exit 1
    fi

    # Get most recent sql file from dbFiles
    sql_file=$(ls ${DB_FILES}/*.sql* -Art | tail -n1)

    if [ ! -f ${WEB_FILES}/config.php.original ]; then
        mv ${WEB_FILES}/config.php ${WEB_FILES}/config.php.original
        # Change config to debug, adjust db and change site to dev
        cat ${WEB_FILES}/config.php.original \
            | sed "s:'debug' => false:'debug' => true:" \
            | sed 's/localhost/db/' \
            | sed -E "s:'database' => '.*?':'database' => '${MYSQL_DATABASE}':" \
            | sed -E "s:'username' => '.*?':'username' => '${MYSQL_USER}':" \
            | sed -E "s:'password' => '.*?':'password' => '${MYSQL_PASSWORD}':" \
            | sed -E "s;'url' => '.*?';'url' => 'https://${DEV_SITE}';" \
            > ${WEB_FILES}/config.php
    fi

    docker-compose up -d

    echo Waiting for database server to come online.
    docker exec -i "$COMPOSE_PROJECT_NAME"_db_1 bash -c \
      "while ! mysql --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} -e 'SELECT 1' &> /dev/null; do echo -n .; sleep 1; done"
    echo All good! Loading "$sql_file" now..

    # Load the most recently modified sql file in dbFiles
    # Modify email host to null to prevent accidental emails
    cat "$sql_file" \
        | sed "s:'mail_host','${SMTP_HOST}':'mail_host','${RESET_MSG}':" \
        | sed "s:'flarum-pusher.app_secret','${PUSHER_APP_SECRET}':'flarum-pusher.app_secret','${RESET_MSG}':" \
        | docker container exec -i "${COMPOSE_PROJECT_NAME}"_db_1 mysql -u$MYSQL_USER -p"$MYSQL_PASSWORD" $MYSQL_DATABASE
    docker container exec -it "${COMPOSE_PROJECT_NAME}"_web_1 php flarum cache:clear
    echo All done! Open up https://"$DEV_SITE"
enter:
    docker container exec -it "${COMPOSE_PROJECT_NAME}"_web_1 bash
stop:
    docker-compose down --volumes
    mv ${WEB_FILES}/config.php.original ${WEB_FILES}/config.php 
build:
    docker-compose build
logs:
    docker container logs -f "${COMPOSE_PROJECT_NAME}"_web_1
