defmodule DriftWeb.LogControllerTest do
  use DriftWeb.ConnCase

  alias Drift.LogEntry
  alias Drift.Repo

  setup do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries = [
      %{timestamp: DateTime.add(now, -60, :second), severity: "info", source: "api-gateway", message: "User 1234 logged in", metadata: %{}, inserted_at: now},
      %{timestamp: DateTime.add(now, -120, :second), severity: "error", source: "payment-worker", message: "Payment failed for order 5678", metadata: %{"attempt" => 3}, inserted_at: now},
      %{timestamp: DateTime.add(now, -180, :second), severity: "debug", source: "cache-layer", message: "Cache hit for key session:abc", metadata: %{}, inserted_at: now}
    ]

    Repo.insert_all(LogEntry, entries)

    on_exit(fn ->
      Repo.delete_all(LogEntry)
    end)

    :ok
  end

  test "GET /api/logs returns paginated JSON", %{conn: conn} do
    conn = get(conn, "/api/logs")
    assert json_response(conn, 200)
    body = json_response(conn, 200)
    assert is_list(body["entries"])
    assert body["page_number"] == 1
    assert body["total_entries"] == 3
  end

  test "GET /api/logs supports severity filter", %{conn: conn} do
    conn = get(conn, "/api/logs?severity=error")
    body = json_response(conn, 200)
    assert body["total_entries"] == 1
    assert hd(body["entries"])["severity"] == "error"
  end

  test "GET /api/logs/:id returns a single log", %{conn: conn} do
    [entry | _] = Repo.all(LogEntry)
    conn = get(conn, "/api/logs/#{entry.id}")
    body = json_response(conn, 200)
    assert body["id"] == entry.id
  end

  test "POST /api/logs creates a log entry", %{conn: conn} do
    conn = post(conn, "/api/logs", %{
      "log_entry" => %{
        "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "severity" => "warning",
        "source" => "test-service",
        "message" => "Test warning message"
      }
    })
    assert json_response(conn, 201)["severity"] == "warning"
  end

  test "POST /api/logs returns 422 on invalid data", %{conn: conn} do
    conn = post(conn, "/api/logs", %{
      "log_entry" => %{
        "severity" => "invalid",
        "source" => "x",
        "message" => ""
      }
    })
    assert json_response(conn, 422)
  end
end
