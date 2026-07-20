defmodule DriftWeb.LogDetailLive do
  use DriftWeb, :live_view

  alias Drift.{Log, LogEntry, Repo}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :log, nil)}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    log = fetch_log(id)

    if log do
      related = Log.related_logs(log, 8)
      {:noreply, assign(socket, log: log, related_logs: related)}
    else
      {:noreply,
       socket
       |> assign(:log, nil)
       |> assign(:related_logs, [])
       |> put_flash(:error, "Log entry not found")}
    end
  end

  defp fetch_log(id) do
    case Integer.parse(id) do
      {int_id, ""} ->
        Repo.get(LogEntry, int_id)

      _ ->
        nil
    end
  end
end
