defmodule Drift.Repo do
  use Ecto.Repo,
    otp_app: :drift,
    adapter: Ecto.Adapters.SQLite3
end
