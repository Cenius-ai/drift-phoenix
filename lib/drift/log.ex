defmodule Drift.Log do
  @moduledoc """
  Context module for log entries — queries, pagination, filtering, and insertion.

  All queries are parameterised via Ecto; dynamic column names (sort) resolve
  through an explicit allowlist.
  """

  import Ecto.Query, warn: false
  alias Drift.Repo
  alias Drift.LogEntry

  @default_page_size 50
  @sort_allowlist %{"timestamp" => :desc, "severity" => :asc, "source" => :asc}

  @doc """
  Returns a map with :entries, :page_number, :page_size, :total_entries, and
  :total_pages for the given filters.

  page_size is configurable (default 50).
  """
  def list_logs(page \\ 1, severity \\ nil, search \\ nil, sort \\ "timestamp", page_size \\ @default_page_size) do
    order_dir = Map.get(@sort_allowlist, sort, :desc)

    base =
      from l in LogEntry,
        order_by: [{^order_dir, l.timestamp}, desc: l.id]

    filtered =
      base
      |> filter_by_severity(severity)
      |> filter_by_search(search)

    total = Repo.aggregate(filtered, :count, :id)
    page_num = max(page, 1)
    ps = max(page_size, 1)
    offset = (page_num - 1) * ps

    entries =
      filtered
      |> limit(^ps)
      |> offset(^offset)
      |> Repo.all()

    %{
      entries: entries,
      page_number: page_num,
      page_size: ps,
      total_entries: total,
      total_pages: max(1, ceil(total / ps))
    }
  end

  @doc """
  Returns a single log entry by id, or nil.
  """
  def get_log!(id) do
    Repo.get!(LogEntry, id)
  end

  @doc """
  Returns recent log entries matching the same source as the given entry,
  excluding the entry itself. Useful for "related logs" sidebars.
  """
  def related_logs(%LogEntry{source: source, id: id}, limit \\ 10) do
    from(l in LogEntry,
      where: l.source == ^source and l.id != ^id,
      order_by: [desc: l.timestamp],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Inserts a new log entry and broadcasts it via PubSub for real-time streaming.
  """
  def create_log(attrs \\ %{}) do
    %LogEntry{}
    |> LogEntry.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, entry} ->
        Phoenix.PubSub.broadcast(Drift.PubSub, "logs:new", {:new_log, entry})
        {:ok, entry}

      error ->
        error
    end
  end

  # -- private helpers --

  defp filter_by_severity(query, nil), do: query
  defp filter_by_severity(query, ""), do: query

  defp filter_by_severity(query, severity) when is_binary(severity) do
    where(query, [l], l.severity == ^severity)
  end

  defp filter_by_search(query, nil), do: query
  defp filter_by_search(query, ""), do: query

  defp filter_by_search(query, term) when is_binary(term) do
    like_term = "%#{term}%"
    where(query, [l],
      like(l.message, ^like_term) or
        like(l.source, ^like_term) or
        fragment("CAST(? AS TEXT) LIKE ?", l.metadata, ^like_term)
    )
  end
end
