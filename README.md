# OMGDEFOLD

This is [OMGSERVERS](https://github.com/OMGSERVERS/omgservers) SDK
and [Project Template](https://defold.com/manuals/editor-templates/)
for [Defold Engine](https://github.com/defold/defold).

---

## OMGSERVERS SDK

This Defold project is configured to share the `omgservers` directory, which contains:

- [OMGPLAYER SDK](https://github.com/OMGSERVERS/omgdefold/tree/main/omgservers/omgplayer): used to interact with the
  backend from game clients.
- [OMGSERVER SDK](https://github.com/OMGSERVERS/omgdefold/tree/main/omgservers/omgserver): used to execute
  backend-specific commands from game runtimes.

It can be included in a game project by following the instructions provided in
the [Defold documentation](https://defold.com/manuals/libraries/#setting-up-library-dependencies).

### Dependencies

- [Defold WebSocket Extension](https://github.com/defold/extension-websocket)
- [Defold Cryptography Extension](https://github.com/defold/extension-crypt)

---

## Project Template

- [Game-side](https://github.com/OMGSERVERS/omgdefold/tree/main/game): contains the game-side logic of the demo
  project using OMGPLAYER SDK.
- [Server-side](https://github.com/OMGSERVERS/omgdefold/tree/main/server): contains the server-side logic of the demo
  project using OMGSERVER SDK.
- [Docker Compose](https://github.com/OMGSERVERS/omgdefold/tree/main/localtesting): use this to start OMGSERVERS in a
  local environment for testing purposes.
- [Dockerfile](https://github.com/OMGSERVERS/omgdefold/blob/main/Dockerfile): used to build the game runtime as a
  headless Defold build using `bob.jar`.
- [Config JSON](https://github.com/OMGSERVERS/omgdefold/blob/main/config.json): provides matchmaking and custom
  configuration for the game.
- [Server Settings](https://github.com/OMGSERVERS/omgdefold/blob/main/server.settings): contains separate settings for
  building a headless version of the game.
- [Localtesting Script](https://github.com/OMGSERVERS/omgdefold/blob/main/omglocaltestingctl.sh): A script to perform
  the most common local testing operations.
