# OMGDEFOLDSDK

This is [OMGSERVERS](https://github.com/OMGSERVERS/omgservers) SDK
for [Defold Engine](https://github.com/defold/defold).
It can be included in a game project by following the instructions provided in
the [Defold documentation](https://defold.com/manuals/libraries/#setting-up-library-dependencies).

### Dependencies

- [Defold WebSocket Extension](https://github.com/defold/extension-websocket)
- [Defold Cryptography Extension](https://github.com/defold/extension-crypt)

### Getting Started

1. `curl -L https://github.com/OMGSERVERS/omgservers/releases/download/0.3.0/install.sh | bash`
1. `./omgserversctl.sh developer local init-tenant`
1. `docker build -t omgservers/localtesting:latest .`
1. `./omgserversctl.sh developer local deploy-version -c config.json -i omgservers/localtesting:latest`
