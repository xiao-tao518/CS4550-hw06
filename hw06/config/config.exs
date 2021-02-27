# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :hw06,
  namespace: Bulls

# Configures the endpoint
config :hw06, BullsWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "cezuzk8iboa8/alsBpYN1oXpkz4BsWa6w2Tq5wWeLtuC7JTYPHYqYyxd9gwDiOem",
  render_errors: [view: BullsWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Bulls.PubSub,
  live_view: [signing_salt: "2ziWpY0e"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
