FROM alpine

RUN apk add --no-cache bash make curl jq

COPY bin/tools.sh /usr/local/bin/tools
COPY bin/poll.sh /usr/local/bin/poll
COPY bin/archive.sh /usr/local/bin/archive
COPY bin/print.sh /usr/local/bin/print
COPY bin/compile.sh /usr/local/bin/compile
COPY bin/Makefile /Makefile

ENTRYPOINT [ "make", "-f", "/Makefile"]

WORKDIR /build

CMD [ "poll" ]
