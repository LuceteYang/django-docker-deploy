# django-docker-deploy
docker를 이용하여 django 배포하는 방식을 정리하였습니다.

## 1. 배포 전 사전 준비
1. 환경설정 변수 정리 => `.env` 파일 생성하여 정리   
2. 필요 모듈 정리 => `requirements, settings.production` 환경 파일 정리

## 2. DockerFile 작성
```docker
# <django_project>/Dockerfile-dev
FROM python:3.6 		# 파이썬 3.6.4버전을 베이스 이미지로 사용합니다.

RUN mkdir /code 		# 컨테이너에 /code 디렉토리를 생성합니다.

WORKDIR /code 			# /code 디렉토리로 워킹 디렉토리를 변경합니다.

ADD ./requirements/base.txt /code/requirements/base.txt # 로컬 위치의 base.txt 파일을 /code/requirements/ 디렉토리 하위로 복사합니다.

ADD ./requirements/local.txt /code/requirements/local.txt # local.txt도 똑같이 실행합니다.

RUN pip install -r /code/requirements/local.txt # 프로젝트에 필요한 파이썬 패키지를 설치합니다.

ADD . /code				# 로컬 위치의 모든 파일 및 디렉토리를 /code/ 디렉토리 하위로 복사합니다.
```

## 3. docker-compose 작성
```docker
# <django_project>/docker-compose.yml

version: '3'		# doceker compose 정의 파일의 버전
services:			# 서비스 정의
  web:				# 서비스명
    build:			# 빌드 지정
      context: . 	# Dockerfile이 있는 디렉토리의 경로
      dockerfile: Dockerfile-dev 	# 도커파일명
    command: python manage.py runserver 0.0.0.0:8000 	# 컨테이너 안에서 작동하는 명령 지정
    volumes: 		# 컨테이너에 볼륨을 마운트합니다.
      - .:/code
    ports: 			# 컨테이너가 공개하는 포트는 ports로 지정합니다.
      - "8000:8000" # <호스트 머신의 포트 번호>:<컨테이너의 포트 번호>
```

## 4. docker-compose 명령어로 이미지를 빌드하여 실행
```zsh
$ docker-compose up --build
```
http://localhost:8000 확인

## 5. nginx & gunicorn + django
```docker
# <django_project>/Dockerfile-dev
FROM python:3.6

RUN mkdir /code

WORKDIR /code

ADD ./requirements/base.txt /code/requirements/base.txt

ADD ./requirements/production.txt /code/requirements/production.txt # production.txt로 변경

RUN pip install -r /code/requirements/production.txt

ADD . /code

RUN ["chmod", "+x", "start.sh"] # bash script 권한 설정

ENTRYPOINT ["sh","./start.sh"] # bash script 실행
```

```zsh
##!/bin/bash

set +e 
echo "==> Django setup, executing: migrate pro"
python  manage.py migrate --settings=config.settings.production --fake-initial
echo "==> Django setup, executing: collectstatic"
python  manage.py collectstatic --settings=config.settings.production --noinput -v 3
echo "==> Django deploy"
gunicorn -b 0.0.0.0:8000 --env DJANGO_SETTINGS_MODULE=config.settings.production deploy_test.wsgi:application 
```

```docker
# <django_project>/docker-compose.yml

version: '3'
services:
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - .:/code
      - ./config/nginx:/etc/nginx/conf.d
    depends_on:	#  서비스의 의존관계 정의 컨테이너의 시작 순서만 제어 
      - web
  web:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - .:/code
    ports:
      - "8000:8000"
    env_file:
      - .env
```
```yml
# <django_project>/config/nginx/default.conf
# proxy_pass 지시자를 통해 nginx가 받은 요청을 넘겨줄 서버를 정의
upstream website {
  server web:8000;
}

server {
  # static 파일을 제공해야할 경우
  location /static/ {
    autoindex on;
    alias /code/staticfiles/;
  }
  location /media/ {
    autoindex on;
    alias /code/deploy_test/media/;
  }
  # 프록시 설정, nginx 뒤에 WAS가 있을 경우
  location / {
    proxy_pass http://website/;
  }  
  # 포트 설정
  listen 80;
  server_name localhost;
}

```
## docker-compose 명령어로 이미지를 빌드하여 실행

```
$ docker-compose up --build
```
https://localhost 로 확인


## troubleshooting
1. gunicorn으로 돌릴때 wsgi.py가 config에 있으니 인식을 못함 => deploy_test/deploy_test로 옮기니 인식함, base.py에서 WSGI_APPLICATION 올긴 경로 바꿔줌

2. python manage.py나 gunicorn 돌릴때 환경변수파일 설정

3. nginx에서 config 옮길 위치 잘 확인하기 /etc/nginx/conf.d

4. dockerfile 빌드 시 collectstatic가 실행이 안됨 => bash script로 실행으로 해결
```zsh
$ find / -name nginx.conf # nginx.conf 경로 확인
```

## 자주쓴 도커 명령어
```zsh
# 컨테이너 전체 삭제
$ docker stop $(docker ps -a -q)
$ docker rm $(docker ps -a -q)
# 이미지 전체 삭제
$ docker rmi $(docker images -q)
#이미지 tag none인것만 삭제
$ docker rmi $(docker images -f "dangling=true" -q)
# 배쉬 접속
$ docker exec -it fc8761f89097 /bin/bash

$ docker ps

$ docker ps -a

$ docker images

$ docker-compose up --build

$ docker logs--details b3041323ae04
```



## 참고 사이트
[https://wikidocs.net/6601](https://wikidocs.net/6601)  
[https://inma.tistory.com/125](https://inma.tistory.com/125)