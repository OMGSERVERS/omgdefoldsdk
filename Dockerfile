FROM --platform=linux/amd64 omgservers/bob:1.0.0-SNAPSHOT AS builder

COPY . /project
RUN touch client/localtesting.lua
RUN java -jar bob.jar --variant headless --platform x86_64-linux --archive --settings server.settings --verbose \
    distclean resolve build bundle

FROM --platform=linux/amd64 ubuntu:latest

WORKDIR /game
COPY --from=builder /project/build/default/omgdefold .
RUN ls -lah .

CMD ["./omgdefold.x86_64"]