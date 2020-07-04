FROM alpine

RUN apk add --no-cache bash curl jq

ADD bin/get.sh /get.sh

ENTRYPOINT [ "/get.sh" ]

WORKDIR /build
