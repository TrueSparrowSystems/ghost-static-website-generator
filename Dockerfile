FROM bash:5.1.16-alpine3.15

RUN apk add --no-cache zip curl jq wget aws-cli

ENV GHOST_STATIC_CONTENT_DIR=/src/content

COPY entrypoint.sh /entrypoint.sh
RUN mkdir -p ${GHOST_STATIC_CONTENT_DIR}
COPY run.sh /src/

ENTRYPOINT ["/entrypoint.sh"]
