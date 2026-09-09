# Database migration helper.
#
# Intended behaviour: wrap golang-migrate against DATABASE_URL with up, down, force and
# version subcommands. Refuses destructive operations when APP_ENV=production unless an
# explicit confirmation flag is passed.
