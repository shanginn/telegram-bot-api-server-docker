FROM alpine:3.24.1 AS builder

ARG TELEGRAM_BOT_API_REF=adfd7f6a8e990272851777eeb3ae0def4216f161

RUN apk update && apk upgrade && \
    apk --no-cache add --update alpine-sdk linux-headers git zlib-dev openssl-dev gperf cmake

RUN git clone https://github.com/tdlib/telegram-bot-api.git /telegram-bot-api && \
    git -C /telegram-bot-api checkout --detach "${TELEGRAM_BOT_API_REF}" && \
    git -C /telegram-bot-api submodule update --init --recursive

WORKDIR /telegram-bot-api/build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr/local ..
RUN cmake --build . --target install

FROM alpine:3.24.1

RUN apk --no-cache add libstdc++ openssl zlib

COPY --from=builder /usr/local/bin/telegram-bot-api /usr/local/bin/telegram-bot-api

ENTRYPOINT ["telegram-bot-api"]
