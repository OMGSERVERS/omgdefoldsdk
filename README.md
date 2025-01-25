# OMGDEFOLD

[OMGSERVERS](https://github.com/OMGSERVERS/omgservers) SDK for [Defold Engine](https://github.com/defold/defold).

# Dependencies

- https://github.com/defold/extension-websocket
- https://github.com/defold/extension-crypt

# How to touch it?

- Run local environment: `./localtesting_up.sh`
- Bootstrap server side: `./localtesting_boot.sh`
- Open `game.project` and press `Project -> Build`

# Local testing

## Initialization

- Run local environment in docker: `./localtesting_up.sh`
- Initialize local tenant and developer account: `./localtesting_init.sh`
- Get tenant details: `./localtesting_details.sh`

## Development loop

- Build docker image: `./localtesting_build.sh`
- Deploy latest build: `./localtesting_deploy.sh`

## Cleaning up

- Stop environment: `./localtesting_down.sh`
- Reset environment: `./localtesting_reset.sh`

## Debugging

- Stream service logs: `./localtesting_logs.sh service -f`