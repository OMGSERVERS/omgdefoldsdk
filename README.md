# OMGDEFOLDSDK

This is [OMGSERVERS](https://github.com/OMGSERVERS/omgservers) SDK
for [Defold Engine](https://github.com/defold/defold).

This project is configured to share the `omgservers` directory, which contains:

- [OMGPLAYER SDK](https://github.com/OMGSERVERS/omgdefold/tree/main/omgservers/omgplayer): used for game clients to
  interact with the backend.
- [OMGRUNTIME SDK](https://github.com/OMGSERVERS/omgdefold/tree/main/omgservers/omgruntime): used for executing
  backend-specific commands from game runtimes.

It can be included in a game project by following the instructions provided in
the [Defold documentation](https://defold.com/manuals/libraries/#setting-up-library-dependencies).

### Dependencies

- [Defold WebSocket Extension](https://github.com/defold/extension-websocket)
- [Defold Cryptography Extension](https://github.com/defold/extension-crypt)

### Getting Started with the Sample Project

- Run `./omgprojectctl.sh build` to build the game runtime in a Docker container.
- Run `./omgprojectctl.sh start` to start the local testing environment in Docker.
- Run `./omgprojectctl.sh init` to initialize a project and developer account.
- Run `./omgprojectctl.sh install` to install the game runtime locally.

- Open `game.project` in Defold and run it.