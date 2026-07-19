defmodule DriftWeb.LogListLiveTest do
  use DriftWeb.ConnCase
  import Phoenix.LiveViewTest

  alias Drift.LogEntry
  alias Drift.Repo

  setup do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries = for i <- 1..60 do
      %{
        timestamp: DateTime.add(now, -i * 10, :second),
        severity: Enum.at(~w(debug info warning error fatal), rem(i, 5)),
        source: Enum.at(~w(api-gateway auth-service cache-layer), rem(i, 3)),
        message: "Test log message number #{i}",
        metadata: %{},
        inserted_at: now
      }
    end

    Repo.insert_all(LogEntry, entries)

    on_exit(fn ->
      Repo.delete_all(LogEntry)
    end)

    :ok
  end

  test "renders log list with entries", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/logs")
    assert html =~ "Logs"
    assert html =~ "entries"
  end

  test "displays severity filter", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/logs")
    html = render(view)
    assert html =~ "All severities"
  end

  test "pagination shows when more than one page", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/logs")
    assert html =~ "Next"
  end

  test "can toggle add-log form", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/logs")

    html_before = render(view)
    refute html_before =~ "New Log Entry"

    view
    |> element("button", "+ Add Log")
    |> render_click()

    html_after = render(view)
    assert html_after =~ "New Log Entry"
  end

  test "can submit add-log form", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/logs")

    view
    |> element("button", "+ Add Log")
    |> render_click()

    view
    |> form("form[phx-submit=create-log]", %{
      "severity" => "error",
      "source" => "test-ui",
      "message" => "Manually created log entry"
    })
    |> render_submit()

    assert Repo.get_by(LogEntry, source: "test-ui", message: "Manually created log entry")
  end
end
