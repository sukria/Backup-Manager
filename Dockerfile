FROM corecanarias/docker-ubuntu
MAINTAINER corecanarias

RUN apt-get update && apt-get install -y build-essential mysql-server

CMD ["/usr/bin/supervisord"]
