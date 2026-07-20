defmodule Drift.LogTest do
  use Drift.DataCase

  alias Drift.Log
  alias Drift.LogEntry
  alias Drift.Repo

  setup do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries = [
      %{timestamp: DateTime.add(now, -60, :second), severity: "info", source: "api-gateway", message: "User 1234 logged in", metadata: %{}, inserted_at: now},
      %{timestamp: DateTime.add(now, -120, :second), severity: "error", source: "payment-worker", message: "Payment failed for order 5678", metadata: %{"attempt" => 3}, inserted_at: now},
      %{timestamp: DateTime.add(now, -180, :second), severity: "debug", source: "cache-layer", message: "Cache hit for key session:abc", metadata: %{"region" => "us-east-1"}, inserted_at: now},
      %{timestamp: DateTime.add(now, -240, :second), severity: "warning", source: "api-gateway", message: "Slow query detected: 450ms", metadata: %{"query" => "SELECT"}, inserted_at: now},
      %{timestamp: DateTime.add(now, -300, :second), severity: "fatal", source: "db-replicator", message: "Data corruption in shard 3", metadata: %{"shard" => 3}, inserted_at: now}
    ]

    Repo.insert_all(LogEntry, entries)

    on_exit(fn ->
      Repo.delete_all(LogEntry)
    end)

    %{now: now}
  end

  test "list_logs/0 returns paginated results" do
    result = Log.list_logs(1)
    assert length(result.entries) == 5
    assert result.page_number == 1
    assert result.page_size == 50
    assert result.total_entries == 5
    assert result.total_pages == 1
  end

  test "list_logs/2 filters by severity" do
    result = Log.list_logs(1, "error")
    assert result.total_entries == 1
    assert hd(result.entries).severity == "error"
  end

  test "list_logs/3 filters by search term across message, source, and metadata" do
    result = Log.list_logs(1, nil, "cache")
    assert result.total_entries == 1
    assert hd(result.entries).source == "cache-layer"

    result2 = Log.list_logs(1, nil, "payment")
    assert result2.total_entries == 1

    result3 = Log.list_logs(1, nil, "us-east-1")
    assert result3.total_entries == 1
  end

  test "get_log!/1 returns a log entry" do
    [first | _] = Log.list_logs(1).entries
    log = Log.get_log!(first.id)
    assert log.id == first.id
  end

  test "get_log!/1 raises on missing id" do
    assert_raise Ecto.NoResultsError, fn ->
      Log.get_log!(-1)
    end
  end

  test "create_log/1 inserts and broadcasts" do
    Phoenix.PubSub.subscribe(Drift.PubSub, "logs:new")

    {:ok, entry} = Log.create_log(%{
      timestamp: DateTime.utc_now(),
      severity: "info",
      source: "test-runner",
      message: "Test log entry"
    })

    assert entry.severity == "info"
    assert entry.source == "test-runner"

    assert_received {:new_log, ^entry}
  end

  test "related_logs/1 returns entries from the same source" do
    [entry | _] = Log.list_logs(1, nil, "api-gateway").entries
    related = Log.related_logs(entry, 5)
    assert length(related) > 0
    Enum.each(related, fn r ->
      assert r.source == entry.source
      assert r.id != entry.id
    end)
  end
end
