Microsoft does not provide a runnable docker container for the linux minecraft bedrock server, this project fixes that.

## How it works:

1. Every day, a GitHub action cron job runs checks https://www.minecraft.net/en-us/download/server/bedrock for a version update.
   * Files in src/resources are updated
2. If there are changes, a new git tag is created
3. On new tag creation, the image is build and pushed to the Github GHCR.io image repo (listed under "Packages")

## Running the application:

1. All properties within `server.properties` are able to be set at runtime. They are all translated to SHOUTING_SNAKE_CASE
   * All detected properties will be printed to STDOUT at startup
3. `docker run ghcr.io/jamcole/minecraft-bedrock-image:latest -v data:/srv/data -p 19132:19132 -e LEVEL_NAME="My Bedrock World"`
4. The following environment variables will map to appropriate permissions in `permissions.json`
   * XUIDS_MEMBERS=xxuid1,xxuid2 -> member
   * XUIDS_OPS=xxuid1,xxuid2 -> operator
   * XUIDS_VISITORS=xxuid1,xxuid2 -> visitor
5. Liveness of the application can be done using `/usr/local/bin/mc-monitor status-bedrock -host $HOSTNAME -port 19132`
