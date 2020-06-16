#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${SCRIPT_DIR}"/.env

start() {
    #!/usr/bin/env bash
    (
        cd "${SCRIPT_DIR}"

        # Get most recent sql file from dbFiles
        sql_file=$(ls ${DB_FILES}/*.sql -Art | head -n1)

        if [ ! -f "${WEB_FILES}"/config.php.original ]; then
            mv "${WEB_FILES}"/config.php "${WEB_FILES}"/config.php.original
            # Change config to debug, adjust db and change site to dev
            cat "${WEB_FILES}"/config.php.original \
                | sed "s:'debug' => false:'debug' => true:" \
                | sed -E "s:'database' => '.*?':'database' => '${MYSQL_DATABASE}':" \
                | sed -E "s:'username' => '.*?':'username' => '${MYSQL_USER}':" \
                | sed -E "s:'password' => '.*?':'password' => '${MYSQL_PASSWORD}':" \
                | sed 's/localhost/db/' \
                | sed 's;'"$PRODUCTION_SITE"';'https://"$DEV_SITE"';' \
                > "${WEB_FILES}"/config.php
        fi

        docker-compose up -d

        echo Waiting for database server to come online.
        while [[ ! $(curl --silent ${CONTAINER_DB_HOST}:${CONTAINER_DB_PORT}; echo $? | grep --quiet -E '23') ]]; do echo -n .; sleep 1; done
        echo All good! Loading "$sql_file" now..

        # Load the most recently modified sql file in dbFiles
        # Modify email host to null to prevent accidental emails
        cat "$sql_file" \
            | sed 's/'"${SMTP_HOST}"'/null/' \
            | docker container exec -i "${COMPOSE_PROJECT_NAME}"_db_1 mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"
        docker container exec -it "${COMPOSE_PROJECT_NAME}"_web_1 php flarum cache:clear
        echo All done! Open up https://"$DEV_SITE"
    )
}
enter() {
    (
        cd "${SCRIPT_DIR}"
        docker container exec -it "${COMPOSE_PROJECT_NAME}"_web_1 bash
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
        docker container logs -f "${COMPOSE_PROJECT_NAME}"_web_1
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
        exit 1
        ;;
esac
