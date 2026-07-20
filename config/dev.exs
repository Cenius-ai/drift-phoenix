import Config

# Configure SQLite database — relative path inside the project
config :drift, Drift.Repo,
  database: "priv/repo/drift_dev.db",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Bind to 0.0.0.0 so the server is reachable from outside the container
config :drift, DriftWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "oUMY6HE6KQTPLF1cZf9Ncbgc1T8apGvK9HmqpWvGHqL19wCedGQ+ktmv/688tIur",
  watchers: []

# Reload browser tabs when matching files change
config :drift, DriftWeb.Endpoint,
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r"priv/static/(?!uploads/).*\.(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/drift_web/router\.ex$",
      ~r"lib/drift_web/(controllers|live|components)/.*\.(ex|heex)$"
    ]
  ]

config :drift, dev_routes: true

config :logger, :default_formatter, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  debug_heex_annotations: true,
  debug_attributes: true,
  enable_expensive_runtime_checks: true
