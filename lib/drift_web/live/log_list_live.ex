defmodule DriftWeb.LogListLive do
  use DriftWeb, :live_view

  alias Drift.Log

  @page_size 50

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Drift.PubSub, "logs:new")
    end

    {:ok,
     socket
     |> assign(:page, 1)
     |> assign(:severity, nil)
     |> assign(:search, nil)
     |> assign(:sort, "timestamp")
     |> assign(:logs, [])
     |> assign(:total_pages, 1)
     |> assign(:total_entries, 0)
     |> assign(:show_add_form, false)
     |> load_logs()}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    page = String.to_integer(params["page"] || "1")
    severity = blank_to_nil(params["severity"])
    search = blank_to_nil(params["search"])
    sort = params["sort"] || "timestamp"

    {:noreply,
     socket
     |> assign(:page, page)
     |> assign(:severity, severity)
     |> assign(:search, search)
     |> assign(:sort, sort)
     |> load_logs()}
  end

  @impl true
  def handle_event("filter", %{"severity" => severity}, socket) do
    {:noreply,
     socket
     |> push_patch(to: DriftWeb.Helpers.build_path(1, blank_to_nil(severity), socket.assigns.search, socket.assigns.sort))}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply,
     socket
     |> push_patch(to: DriftWeb.Helpers.build_path(1, socket.assigns.severity, blank_to_nil(search), socket.assigns.sort))}
  end

  @impl true
  def handle_event("clear-filters", _params, socket) do
    {:noreply, push_patch(socket, to: "/logs")}
  end

  @impl true
  def handle_event("toggle-add-form", _params, socket) do
    {:noreply, assign(socket, :show_add_form, !socket.assigns.show_add_form)}
  end

  @impl true
  def handle_event("create-log", %{"severity" => severity, "source" => source, "message" => message}, socket) do
    attrs = %{
      timestamp: DateTime.utc_now(),
      severity: severity,
      source: source,
      message: message,
      metadata: %{"created_via" => "ui"}
    }

    case Log.create_log(attrs) do
      {:ok, _entry} ->
        {:noreply,
         socket
         |> assign(:show_add_form, false)
         |> put_flash(:info, "Log entry created")}

      {:error, changeset} ->
        errors = inspect_changeset_errors(changeset)
        {:noreply, put_flash(socket, :error, "Failed to create log: #{errors}")}
    end
  end

  @impl true
  def handle_event("simulate-log", _params, socket) do
    severities = ~w(debug info warning error fatal)
    sources = ~w(api-gateway auth-service user-service payment-worker notification-bus)
    messages = [
      "User #{Enum.random(1000..9999)} performed action #{Enum.random(~w(login purchase view search))}",
      "Request to /api/v2/#{Enum.random(~w(users orders products))} completed in #{Enum.random(10..450)}ms",
      "Cache #{Enum.random(~w(hit miss expired))} for key #{Enum.random(~w(session-123 profile-456 config-789))}",
      "Worker #{Enum.random(~w(email pdf-report backup))} job finished — status #{Enum.random(~w(ok retry failed))}"
    ]

    attrs = %{
      timestamp: DateTime.utc_now(),
      severity: Enum.random(severities),
      source: Enum.random(sources),
      message: Enum.random(messages),
      metadata: %{
        "host" => "node-#{Enum.random(1..5)}.internal",
        "pid" => Enum.random(1000..99_999),
        "simulated" => true
      }
    }

    case Log.create_log(attrs) do
      {:ok, _entry} ->
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to insert simulated log")}
    end
  end

  @impl true
  def handle_info({:new_log, entry}, socket) do
    if matches_filter?(entry, socket.assigns.severity, socket.assigns.search) do
      logs = [entry | socket.assigns.logs] |> Enum.take(@page_size)
      {:noreply, assign(socket, :logs, logs)}
    else
      {:noreply, socket}
    end
  end

  # -- helpers --

  defp load_logs(socket) do
    %{page: page, severity: severity, search: search, sort: sort} = socket.assigns
    result = Log.list_logs(page, severity, search, sort, 50)

    socket
    |> assign(:logs, result.entries)
    |> assign(:total_pages, result.total_pages)
    |> assign(:total_entries, result.total_entries)
  end

  defp matches_filter?(_entry, nil, nil), do: true

  defp matches_filter?(entry, severity, nil) do
    entry.severity == severity
  end

  defp matches_filter?(entry, nil, search) do
    String.contains?(String.downcase(entry.message), String.downcase(search)) or
      String.contains?(String.downcase(entry.source), String.downcase(search))
  end

  defp matches_filter?(entry, severity, search) do
    entry.severity == severity and matches_filter?(entry, nil, search)
  end

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(str) when is_binary(str), do: str
  defp blank_to_nil(_), do: nil

  defp inspect_changeset_errors(changeset) do
    changeset.errors
    |> Enum.map(fn {field, {msg, _}} -> "#{field}: #{msg}" end)
    |> Enum.join(", ")
  end
end
