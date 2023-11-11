FROM alpine:latest as builder

RUN apk --no-cache add g++ make cmake git openssl-dev gperf linux-headers zlib-dev

RUN git clone --recursive https://github.com/tdlib/telegram-bot-api.git /telegram-bot-api

WORKDIR /telegram-bot-api/build
RUN cmake -DCMAKE_BUILD_TYPE=Release ..
RUN cmake --build . --target install

FROM alpine:latest

RUN apk --no-cache add libstdc++ openssl zlib

COPY --from=builder /usr/local/bin/telegram-bot-api /usr/local/bin/telegram-bot-api

ENTRYPOINT ["telegram-bot-api"]

