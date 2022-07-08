FROM python:3.8

LABEL Gustavo D. Fortti <gustavofortti@gmail.com>

USER root

RUN apt-get update && apt-get install -y git zip

RUN mkdir -p /root/.ssh/
COPY ./package.zip /root/
COPY ./entrypoint.sh /root/

CMD ["sh", "/root/entrypoint.sh"]