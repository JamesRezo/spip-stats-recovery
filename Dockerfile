FROM alpine:3.21

RUN apk add --no-cache bash make curl jq git && \
    adduser --home /build --shell /bin/ash --disabled-password poller poller

COPY bin/tools.sh /usr/local/bin/tools
COPY bin/poll.sh /usr/local/bin/poll
COPY bin/archive.sh /usr/local/bin/archive
COPY bin/print.sh /usr/local/bin/print
COPY bin/compile.sh /usr/local/bin/compile
COPY bin/save.sh /usr/local/bin/save
COPY bin/Makefile /Makefile
COPY .gitconfig /root
COPY .gitignore_global /root

ENTRYPOINT [ "make", "-f", "/Makefile"]

USER poller
WORKDIR /build

CMD [ "archive" ]
