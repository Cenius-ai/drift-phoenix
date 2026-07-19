defmodule DriftWeb.Helpers do
  @moduledoc """
  Shared template helpers used across LiveViews and components.
  """

  @doc """
  Truncates a log message to fit in the table cell, preserving readability.
  """
  def truncate_message(msg) when is_binary(msg) do
    if String.length(msg) > 120 do
      String.slice(msg, 0, 117) <> "..."
    else
      msg
    end
  end

  def truncate_message(nil), do: "—"

  @doc """
  Builds a query-string path for the log list with the current filters.
  """
  def build_path(page, severity, search, sort) do
    params = []
    params = if page > 1, do: [{"page", Integer.to_string(page)} | params], else: params
    params = if severity && severity != "", do: [{"severity", severity} | params], else: params
    params = if search && search != "", do: [{"search", search} | params], else: params
    params = if sort != "timestamp", do: [{"sort", sort} | params], else: params
    params = Enum.reverse(params)

    query = URI.encode_query(params)
    if query == "", do: "/logs", else: "/logs?#{query}"
  end

  @doc """
  Generates a window of page numbers around the current page.
  """
  def page_range(_page, total) when total <= 7 do
    1..total |> Enum.to_list()
  end

  def page_range(page, total) do
    left = max(1, page - 2)
    right = min(total, page + 2)

    pages =
      if left <= 2 do
        Enum.to_list(1..min(5, total))
      else
        [1, :ellipsis] ++ Enum.to_list(left..right)
      end

    pages =
      if right >= total - 1 do
        (pages -- [:ellipsis]) ++ Enum.to_list(max(total - 4, left + 1)..total)
        |> Enum.uniq()
        |> Enum.sort(fn
          :ellipsis, _ -> true
          _, :ellipsis -> false
          a, b -> a <= b
        end)
      else
        pages ++ [:ellipsis, total]
      end

    pages
  end

  @doc """
  Formats a metadata value for display.
  """
  def format_meta_value(value) when is_boolean(value), do: if(value, do: "true", else: "false")
  def format_meta_value(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 3)
  def format_meta_value(value) when is_map(value), do: Jason.encode!(value, pretty: true)
  def format_meta_value(value) when is_list(value), do: Jason.encode!(value, pretty: true)
  def format_meta_value(value), do: to_string(value)

  @doc """
  Generates a pretty-printed JSON representation of a log entry.
  """
  def raw_json(entry) do
    entry
    |> Map.take([:id, :timestamp, :severity, :source, :message, :metadata, :inserted_at])
    |> Map.new(fn {k, v} -> {k, format_for_json(v)} end)
    |> Jason.encode!(pretty: true)
  end

  defp format_for_json(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp format_for_json(id) when is_binary(id), do: id
  defp format_for_json(v), do: v
end
