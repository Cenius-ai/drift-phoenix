defmodule Drift.LogEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_severities ~w(debug info warning error fatal)

  schema "log_entries" do
    field :timestamp, :utc_datetime
    field :severity, :string, default: "info"
    field :source, :string
    field :message, :string
    field :metadata, :map, default: %{}
    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(log_entry, attrs) do
    log_entry
    |> cast(attrs, [:timestamp, :severity, :source, :message, :metadata])
    |> validate_required([:timestamp, :severity, :source, :message])
    |> validate_inclusion(:severity, @valid_severities)
  end

  def severity_colors do
    %{
      "debug" => "slate",
      "info" => "sky",
      "warning" => "amber",
      "error" => "red",
      "fatal" => "rose"
    }
  end

  def severity_levels, do: @valid_severities
end
