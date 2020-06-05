containerDbHost := "127.0.0.1"
containerDbPort := "9906"

webFiles := "site"

start:
    #!/usr/bin/env bash
    docker-compose up -d
    just prep
    echo All done! Open up $DEV_SITE
enter:
    docker container exec -it $WEBSERVER_CONTAINER bash
stop:
    docker-compose down
prep:
    #!/usr/bin/env bash
    sed -i 's/localhost/db/' {{webFiles}}/config.php
    sed -i 's;$PRODUCTION_SITE;$DEV_SITE;' {{webFiles}}/config.php
    sed -ie '/%{HTTPS} off/,+5d' {{webFiles}}/public/.htaccess
    just disable-email

    while [[ ! $(curl --silent {{containerDbHost}}:{{containerDbPort}}; echo $? | grep --quiet -E '23') ]]; do echo -n .; sleep 1; done
    echo All good! Loading database now..
    cat $DB_FILE | docker container exec -i $DATABASE_CONTAINER mysql -u$MYSQL_USER -p"$MYSQL_PASSWORD" $MYSQL_DATABASE
disable-email: 
    #!/usr/bin/env bash
    sed -i 's/smtp.sendgrid.net/null/' $DB_FILE
build:
    docker-compose build
