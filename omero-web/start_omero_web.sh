function wait_for_db_user {
    output=`psql -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='omero'"`
    while [ $output != 1 ]; do
        echo Waiting for omero user to be created in the database
        sleep 5s
        output=`psql -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='omero'"`
    done
}

cd $OMERO_HOME

if [ $OMERO_WEB_DEVELOPMENT == "no" ]
then

    if [ $OMERO_WEB_USE_SSL == "yes" ]
    then

        # Setup ssl certificates if it is not already here
        if [ ! -f $OMERO_WEB_CERTS_DIR/omero.crt ]; then
            mkdir -p $OMERO_WEB_CERTS_DIR
            cd $OMERO_WEB_CERTS_DIR
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout omero.key -out omero.crt -batch
        fi

    fi

    ./bin/omero config set omero.web.server_list "[[\"omero_server\", 4064, \"omero\"]]"

    # Load applications from /data/omero_web_apps/deploy.sh
    export PYTHONPATH=$OMERO_WEB_DEVELOPMENT_APPS:$PYTHONPATH
    bash /data/omero_web_apps/deploy.sh

    wait_for_db_user

    ./bin/omero web start

else

    mkdir -p $OMERO_WEB_DEVELOPMENT_APPS
    export PYTHONPATH=$OMERO_WEB_DEVELOPMENT_APPS:$PYTHONPATH

    ./bin/omero config set omero.web.application_server development
    ./bin/omero config set omero.web.application_server.host 0.0.0.0
    ./bin/omero config set omero.web.application_server.port 4080
    ./bin/omero config set omero.web.debug True

    ./bin/omero config set omero.web.server_list "[[\"omero_server\", 4064, \"omero\"]]"

    wait_for_db_user
fi

