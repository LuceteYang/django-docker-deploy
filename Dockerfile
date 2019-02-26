FROM python:3.6

RUN mkdir /code

WORKDIR /code

ADD ./requirements/base.txt /code/requirements/base.txt

ADD ./requirements/production.txt /code/requirements/production.txt

RUN pip install -r /code/requirements/production.txt

ADD . /code	

CMD python manage.py makemigrations --settings=config.settings.production && python manage.py migrate --settings=config.settings.production

CMD gunicorn -b 0.0.0.0:8000 --env DJANGO_SETTINGS_MODULE=config.settings.production deploy_test.wsgi:application