FROM ubuntu:bionic

LABEL Gustavo D. Fortti <gustavofortti@gmail.com>

USER root

RUN apt-get update && apt-get install -y \
    git \
    zip \
    python3.8 \
    python3-pip

RUN pip3 install snscrape

RUN mkdir -p /root/.ssh/
COPY ./package.zip /root/
COPY ./entrypoint.sh /root/
COPY ./build-env.sh /root/

CMD ["bash", "/root/entrypoint.sh"]