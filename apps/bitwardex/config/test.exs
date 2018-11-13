# Since configuration is shared in umbrella projects, this file
# should only configure the :bitwardex application itself
# and only for organization purposes. All other config goes to
# the umbrella root.
use Mix.Config

# Configure your database
config :bitwardex, Bitwardex.Repo, pool: Ecto.Adapters.SQL.Sandbox

import_config("test.secret.exs")