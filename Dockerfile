FROM --platform=linux/amd64 openjdk:21-jdk-bullseye AS builder

# Install dependencies
# https://forum.defold.com/t/spine-4-1/72923/2
RUN apt-get update && \
    apt-get install -y --no-install-recommends libopenal-dev libgl1-mesa-dev libglw1-mesa-dev freeglut3-dev zip && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    mkdir /project

WORKDIR /project

RUN SHA1=$(curl -s http://d.defold.com/stable/info.json | sed 's/.*sha1": "\(.*\)".*/\1/') \
    && curl -L -o bob.jar "http://d.defold.com/archive/${SHA1}/bob/bob.jar"

COPY . /project
RUN java -jar bob.jar --variant headless --platform x86_64-linux --archive --settings server.settings --verbose \
    distclean resolve build bundle

FROM --platform=linux/amd64 ubuntu:latest

WORKDIR /game

COPY --from=builder /project/build/default/omgdefoldsdk .
RUN ls -lah .

CMD ["./omgdefoldsdk.x86_64"]