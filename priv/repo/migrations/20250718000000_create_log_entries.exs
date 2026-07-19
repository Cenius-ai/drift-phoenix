defmodule Drift.Repo.Migrations.CreateLogEntries do
  use Ecto.Migration

  def change do
    create table(:log_entries) do
      add :timestamp, :utc_datetime, null: false
      add :severity, :string, null: false, default: "info"
      add :source, :string, null: false
      add :message, :text, null: false
      add :metadata, :map
      add :inserted_at, :utc_datetime, null: false
    end

    create index(:log_entries, [:timestamp])
    create index(:log_entries, [:severity])
    create index(:log_entries, [:severity, :timestamp])
  end
end
