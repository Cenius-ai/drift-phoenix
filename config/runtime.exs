import Config

# Runtime database configuration — only applies in production.
# Dev and test use their own compile-time database paths from dev.exs / test.exs.
if config_env() == :prod do
  db_url = System.get_env("DATABASE_URL")

  if db_url do
    config :drift, Drift.Repo, url: db_url
  else
    db_path = System.get_env("DB_PATH", "priv/repo/drift.db")
    config :drift, Drift.Repo, database: db_path
  end

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "SECRET_KEY_BASE is required in production"

  host = System.get_env("PHX_HOST", "localhost")
  port = String.to_integer(System.get_env("PORT", "4000"))

  config :drift, DriftWeb.Endpoint,
    url: [host: host, port: port],
    http: [ip: {0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base,
    check_origin: false,
    server: true
end
