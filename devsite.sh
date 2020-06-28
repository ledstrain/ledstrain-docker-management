#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${SCRIPT_DIR}"/.env

start() {
    (
        cd "${SCRIPT_DIR}"

        if [ ! -f .env ]; then
            tail -n +2 example.env > .env
            source .env
            mkdir -p ${DB_FILES} ${WEB_FILES}
            echo "No .env file found! Defaults have been loaded. Make sure ${DB_FILES} has a sql export of the forum and ${WEB_FILES} has the site files"
            exit 1
        fi

        if [ "$DISABLE_SSL" == "true" ]; then
            HTTP_PREFIX="http"
        else
            HTTP_PREFIX="https"
        fi

        # Get most recent sql file from dbFiles
        sql_file=$(ls ${DB_FILES}/*.sql* -Art | head -n1)

        if [ ! -f "${WEB_FILES}"/config.php.original ]; then
            mv "${WEB_FILES}"/config.php "${WEB_FILES}"/config.php.original
            # Change config to debug, adjust db and change site to dev
            cat "${WEB_FILES}"/config.php.original \
                | sed "s:'debug' => false:'debug' => true:" \
                | sed '/port/d' \
                | sed -E "s;'host' => '.*?';'host' => 'db';" \
                | sed -E "s:'database' => '.*?':'database' => '${MYSQL_DATABASE}':" \
                | sed -E "s:'username' => '.*?':'username' => '${MYSQL_USER}':" \
                | sed -E "s:'password' => '.*?':'password' => '${MYSQL_PASSWORD}':" \
                | sed -E "s;'url' => '.*?';'url' => '${HTTP_PREFIX}://${DEV_SITE}';" \
                > "${WEB_FILES}"/config.php
        fi

        docker-compose up -d
        DB=$(docker inspect -f '{{ .Name }}' $(docker-compose ps -q db) | cut -c2-)
        WEB=$(docker inspect -f '{{ .Name }}' $(docker-compose ps -q web) | cut -c2-)

        echo Waiting for database server to come online.
        docker exec -i "$DB" bash -c \
          "while ! mysql --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} -e 'SELECT 1' &> /dev/null; do echo -n .; sleep 1; done"
        echo All good! Loading "$sql_file" now..

        # Load the most recently modified sql file in dbFiles
        # Modify email host to null to prevent accidental emails
        (
            if [ ${sql_file: -3} == ".gz" ]; then
                gzip -dc "$sql_file"
            elif [ ${sql_file: -4} == ".sql" ]; then
                cat "$sql_file"
            else
                echo "No valid sql file found"
                exit 1
            fi
        ) \
            | sed "s:'mail_host','${SMTP_HOST}':'mail_host','"${RESET_MSG}"':" \
            | sed "s:'flarum-pusher.app_secret','${PUSHER_APP_SECRET}':'flarum-pusher.app_secret','${RESET_MSG}':" \
            | docker container exec -i "$DB" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"
        docker container exec -it "$WEB" php flarum cache:clear
        echo All done! Open up ${HTTP_PREFIX}://"$DEV_SITE"
    )
}
enter() {
    (
        cd "${SCRIPT_DIR}"
        WEB=$(docker inspect -f '{{ .Name }}' $(docker-compose ps -q web) | cut -c2-)
        docker container exec -it "$WEB" bash
    )
}
stop() {
    (
        cd "${SCRIPT_DIR}"
        docker-compose down --volumes
        mv ${WEB_FILES}/config.php.original ${WEB_FILES}/config.php 
    )
}
build() {
    (
        cd "${SCRIPT_DIR}"
        docker-compose build
    )
}
logs() {
    (
        cd "${SCRIPT_DIR}"
        WEB=$(docker inspect -f '{{ .Name }}' $(docker-compose ps -q web) | cut -c2-)
        docker container logs -f "$WEB"
    )
}

case "$1" in
    "start")
        start
        ;;
    "enter")
        enter
        ;;
    "stop")
        stop
        ;;
    "build")
        build
        ;;
    "logs")
        logs
        ;;
    *)
        echo ""
        echo -e "\t${WEB_FILES} should contain the flarum site files."
        echo -e "\t${DB_FILES} should contain the mysqldump of the database"
        echo ""
        echo -e "\t$0 start"
        echo -e "\t$0 stop"
        echo -e "\t$0 enter  # Enter web instance. Useful to install composer packages"
        echo -e "\t$0 build  # Rebuild the web image"
        echo -e "\t$0 logs   # Follow the web instance logs"
        exit 1
        ;;
esac
