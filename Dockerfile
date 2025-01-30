ARG OMGSERVERS_VERSION
FROM --platform=linux/amd64 omgservers/bob:${OMGSERVERS_VERSION} AS builder

COPY . /project
RUN java -jar bob.jar --variant headless --platform x86_64-linux --archive --settings server.settings --verbose \
    distclean resolve build bundle

FROM --platform=linux/amd64 ubuntu:latest

WORKDIR /game
COPY --from=builder /project/build/default/omgdefold .
RUN ls -lah .

CMD ["./omgdefold.x86_64"]