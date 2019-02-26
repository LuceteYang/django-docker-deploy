#!/bin/bash

set +e 
echo "==> Django setup, executing: migrate pro"
python  manage.py migrate --settings=config.settings.production --fake-initial
echo "==> Django setup, executing: collectstatic"
python  manage.py collectstatic --settings=config.settings.production --noinput -v 3

gunicorn -b 0.0.0.0:8000 --env DJANGO_SETTINGS_MODULE=config.settings.production deploy_test.wsgi:application