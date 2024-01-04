FROM alpine:latest as builder

RUN apk update && apk upgrade && \
    apk --no-cache add --update alpine-sdk linux-headers git zlib-dev openssl-dev gperf cmake

RUN git clone --recursive https://github.com/tdlib/telegram-bot-telegram-server.git /telegram-bot-api

WORKDIR /telegram-bot-api/build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr/local ..
RUN cmake --build . --target install

FROM alpine:latest

RUN apk --no-cache add libstdc++ openssl zlib

COPY --from=builder /usr/local/bin/telegram-bot-api /usr/local/bin/telegram-bot-api

ENTRYPOINT ["telegram-bot-api"]
