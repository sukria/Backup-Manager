FROM corecanarias/docker-ubuntu
MAINTAINER corecanarias

RUN apt-get update && apt-get install -y build-essential mysql-server checkinstall gettext

CMD ["/usr/bin/supervisord"]
