defmodule DriftWeb.LogDetailLiveTest do
  use DriftWeb.ConnCase
  import Phoenix.LiveViewTest
  import Ecto.Query, only: [from: 2]

  alias Drift.LogEntry
  alias Drift.Repo

  setup do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entry = %{
      timestamp: DateTime.add(now, -60, :second),
      severity: "error",
      source: "api-gateway",
      message: "Failed to process payment for order 9876: gateway timeout after 30s",
      metadata: %{"host" => "node-3.internal", "pid" => 12345, "attempt" => 3},
      inserted_at: now
    }

    Repo.insert_all(LogEntry, [entry])

    on_exit(fn ->
      Repo.delete_all(LogEntry)
    end)

    [entry | _] = Repo.all(LogEntry)
    %{entry: entry}
  end

  test "renders log detail for a valid log entry", %{conn: conn, entry: entry} do
    {:ok, _view, html} = live(conn, "/logs/#{entry.id}")

    assert html =~ "Log Entry"
    assert html =~ entry.severity
    assert html =~ entry.source
    assert html =~ "gateway timeout"
    assert html =~ "Metadata"
    assert html =~ "host"
    assert html =~ "node-3.internal"
    assert html =~ "pid"
    assert html =~ "Raw JSON"
  end

  test "shows not found for invalid log id", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/logs/nonexistent-id-99999")

    assert html =~ "not found"
  end

  test "displays back link to log list", %{conn: conn, entry: entry} do
    {:ok, _view, html} = live(conn, "/logs/#{entry.id}")

    assert html =~ "Back to logs"
  end

  test "shows related logs sidebar when same-source entries exist", %{conn: conn} do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries = for i <- 1..5 do
      %{
        timestamp: DateTime.add(now, -i * 120, :second),
        severity: Enum.at(~w(debug info warning error fatal), rem(i, 5)),
        source: "api-gateway",
        message: "Related log message #{i}",
        metadata: %{},
        inserted_at: now
      }
    end

    Repo.insert_all(LogEntry, entries)

    on_exit(fn ->
      Repo.delete_all(LogEntry)
    end)

    [first | _] =
      Repo.all(
        from l in LogEntry,
          where: l.source == "api-gateway",
          order_by: [desc: l.timestamp]
      )

    {:ok, _view, html} = live(conn, "/logs/#{first.id}")

    assert html =~ "Same source"
    assert html =~ "api-gateway"
  end
end
