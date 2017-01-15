FROM alpine:latest

COPY . /

RUN apk add --update \
    python \
    python-dev \
    py2-pip \
    curl \
    bash

RUN pip install awscli
RUN chmod u+x /iterative.sh

ENTRYPOINT ["/iterative.sh"]
