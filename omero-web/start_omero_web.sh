function wait_for_db_user {
    until ${OMERO_HOME}/bin/omero login -s omero_server -p 4064 -u root -w password ; do
        >&2 echo "OMERO.server is unavailable - sleeping"
        sleep 10
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

