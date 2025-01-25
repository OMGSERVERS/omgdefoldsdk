# OMGDEFOLD

The [OMGSERVERS](https://github.com/OMGSERVERS/omgservers) SDK for [Defold Engine](https://github.com/defold/defold).

This Defold project is configured to share the `omgservers` directory, which contains:

- [OMGPLAYER SDK](https://github.com/OMGSERVERS/omgdefold/tree/main/omgservers/omgplayer): used to interact with the
  backend from game clients.
- [OMGSERVER SDK](https://github.com/OMGSERVERS/omgdefold/tree/main/omgservers/omgserver): used to execute
  backend-specific commands from game runtimes.

It can be included in a game project by following the instructions provided in
the [Defold documentation](https://defold.com/manuals/libraries/#setting-up-library-dependencies).

# Dependencies

- [Defold WebSocket Extension](https://github.com/defold/extension-websocket)
- [Defold Cryptography Extension](https://github.com/defold/extension-crypt)

# Sample Project Structure

- [Client-side](https://github.com/OMGSERVERS/omgdefold/tree/main/client): contains the client-side logic of the demo
  project using OMGPLAYER SDK.
- [Server-side](https://github.com/OMGSERVERS/omgdefold/tree/main/server): contains the server-side logic of the demo
  project using OMGSERVER SDK.
- [Docker Compose](https://github.com/OMGSERVERS/omgdefold/tree/main/docker): use this to start OMGSERVERS in a local
  environment for testing purposes.
- [Dockerfile](https://github.com/OMGSERVERS/omgdefold/blob/main/Dockerfile): used to build the game runtime as a
  headless Defold build using `bob.jar`.
- [Config JSON](https://github.com/OMGSERVERS/omgdefold/blob/main/config.json): provides matchmaking and custom
  configuration for game runtimes.
- [Server Settings](https://github.com/OMGSERVERS/omgdefold/blob/main/server.settings): contains separate settings for
  building a headless version of the game.
- [Localtesting Script](https://github.com/OMGSERVERS/omgdefold/blob/main/localtesting.sh): A script to perform the most
  common local testing operations.

# Localtesting

## Quick Bootstrap

1. Start the local environment by running: `./localtesting.sh up`
2. Wait a moment for the services to start, then bootstrap the project server-side by running: `./localtesting.sh boot`
3. Open `game.project` and select **Project -> Build**.

## Initialization

- Run local environment in docker: `./localtesting.sh up`
- Initialize local tenant and developer account: `./localtesting.sh init`
- Get project server-side details: `./localtesting.sh details`

## Development loop

- Build docker image: `./localtesting.sh build`
- Deploy latest build: `./localtesting.sh deploy`

## Cleaning up

- Stop environment: `./localtesting.sh down`
- Reset environment: `./localtesting.sh reset`

## Debugging

- Stream service logs: `./localtesting.sh logs service -f`
- Perform any other operations: `./localtesting.sh ctl <options>`
