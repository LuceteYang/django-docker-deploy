FROM python:3.6

RUN mkdir /code

WORKDIR /code

ADD ./requirements/base.txt /code/requirements/base.txt

ADD ./requirements/production.txt /code/requirements/production.txt

RUN pip install -r /code/requirements/production.txt

ADD . /code	

RUN ["chmod", "+x", "start.sh"]

ENTRYPOINT ["sh","./start.sh"]