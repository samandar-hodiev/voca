# Start the local development stack.
#
# Intended behaviour: bring up infra/compose/docker-compose.dev.yml, wait for PostgreSQL to
# accept connections, apply migrations, load seed content, then run the API.
#
# Goal: a new developer clones the repository and is running with one command.
