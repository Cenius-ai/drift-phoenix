defmodule DriftWeb.LogController do
  use DriftWeb, :controller

  alias Drift.{Log, LogEntry, Repo}

  def index(conn, params) do
    page = String.to_integer(params["page"] || "1")
    severity = params["severity"]
    search = params["search"]
    sort = params["sort"] || "timestamp"
    page_size = String.to_integer(params["page_size"] || "50")

    result = Log.list_logs(page, severity, search, sort, page_size)

    json(conn, %{
      entries: Enum.map(result.entries, &log_entry_json/1),
      page_number: result.page_number,
      page_size: result.page_size,
      total_pages: result.total_pages,
      total_entries: result.total_entries
    })
  end

  def show(conn, %{"id" => id}) do
    case Repo.get(LogEntry, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Log entry not found"})

      log ->
        json(conn, log_entry_json(log))
    end
  end

  def create(conn, %{"log_entry" => params}) do
    case Log.create_log(params) do
      {:ok, entry} ->
        conn
        |> put_status(:created)
        |> json(log_entry_json(entry))

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: changeset_error_map(changeset)})
    end
  end

  defp log_entry_json(entry) do
    %{
      id: entry.id,
      timestamp: entry.timestamp,
      severity: entry.severity,
      source: entry.source,
      message: entry.message,
      metadata: entry.metadata,
      inserted_at: entry.inserted_at
    }
  end

  defp changeset_error_map(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
