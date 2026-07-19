defmodule Drift.Seed do
  @moduledoc false

  alias Drift.Repo
  alias Drift.LogEntry

  def run do
    if Repo.aggregate(LogEntry, :count, :id) == 0 do
      IO.puts("Seeding 12,000 log entries — this may take a moment...")
      do_seed()
      IO.puts("Seeded #{Repo.aggregate(LogEntry, :count, :id)} log entries successfully.")
    else
      IO.puts("Log entries already exist — skipping seed.")
    end
  end

  defp do_seed do
    sources = [
      "api-gateway", "auth-service", "user-service", "payment-worker",
      "notification-bus", "search-indexer", "cache-layer", "db-replicator",
      "rate-limiter", "task-scheduler"
    ]

    severities = ~w(debug info warning error fatal)
    severity_weights = [30, 45, 15, 8, 2]

    debug_templates = [
      "Cache hit for key user:X:profile — TTL Xs remaining",
      "Connection pool stats: X active, X idle, X pending",
      "Request tracing span X completed in Xµs",
      "Polling topic X — no new messages since X",
      "Healthcheck probe from X — all systems nominal"
    ]

    info_templates = [
      "User X logged in from IP X.X.X.X",
      "Order X created — X items, total $X.XX",
      "Deployment vX.X.X rolled out to X nodes",
      "Scheduled job import_reports completed in X.Xs",
      "Webhook from partner X received — event type payment.succeeded",
      "Database backup completed — XMB written to X",
      "Rate limit bucket refilled for tenant X — tokens X",
      "Email delivered to user X — template welcome_v2"
    ]

    warning_templates = [
      "Slow query detected: Xms on table orders — consider adding index",
      "Retry attempt X/X for message X to queue X",
      "Disk usage at X% on volume X — threshold approaching",
      "Connection pool X nearing capacity — X% utilised",
      "Deprecated API version X called by client X",
      "Memory usage spike on node X — XGB RSS"
    ]

    error_templates = [
      "Failed to process payment for order X: gateway timeout after Xs",
      "Database connection refused on host X — retrying in Xs",
      "Unhandled exception in worker X: X at line X",
      "Authentication failure for user X — X consecutive attempts",
      "S3 upload failed for object X: access denied on bucket X",
      "gRPC call to X failed with status DEADLINE_EXCEEDED"
    ]

    fatal_templates = [
      "Out of memory: process X killed by OOM killer — RSS XGB",
      "Data corruption detected in shard X: checksum mismatch at offset X",
      "Cluster partition lost — node X isolated from quorum",
      "Disk failure on mount X: I/O error, filesystem read-only"
    ]

    templates = %{
      "debug" => debug_templates,
      "info" => info_templates,
      "warning" => warning_templates,
      "error" => error_templates,
      "fatal" => fatal_templates
    }

    batch_size = 500
    total = 12_000

    for batch_start <- 0..(div(total, batch_size) - 1) do
      entries =
        for i <- 1..batch_size do
          idx = batch_start * batch_size + i
          seed_val = idx * 73 + 17

          severity = weighted_pick(severities, severity_weights, seed_val)
          source = Enum.at(sources, rem(seed_val, length(sources)))
          template_list = Map.get(templates, severity)
          template = Enum.at(template_list, rem(seed_val, length(template_list)))
          message = fill_template(template, seed_val)

          seconds_ago = round(:math.pow(rem(seed_val, 604_800) / 604_800.0, 0.7) * 604_800)
          ts = DateTime.add(DateTime.truncate(DateTime.utc_now(), :second), -seconds_ago, :second)
          metadata = build_metadata(source, seed_val)

          %{
            timestamp: ts,
            severity: severity,
            source: source,
            message: message,
            metadata: metadata,
            inserted_at: DateTime.truncate(DateTime.utc_now(), :second)
          }
        end

      Repo.insert_all(LogEntry, entries)

      if rem(batch_start + 1, 6) == 0 do
        IO.puts("  ... #{(batch_start + 1) * batch_size} entries inserted")
      end
    end
  end

  defp weighted_pick(items, weights, seed) do
    total = Enum.sum(weights)
    r = rem(seed, total)
    {item, _} =
      Enum.reduce_while(Enum.zip(items, weights), {nil, 0}, fn {item, w}, {_, acc} ->
        if r < acc + w do
          {:halt, {item, acc + w}}
        else
          {:cont, {nil, acc + w}}
        end
      end)
    item
  end

  defp fill_template(template, seed) do
    ~r/X/
    |> Regex.split(template, include_captures: true, trim: true)
    |> Enum.map_reduce(0, fn
      "X", n ->
        val = rem(seed * (n + 1) * 7919, 10_000)
        {Integer.to_string(val), n + 1}
      part, n ->
        {part, n}
    end)
    |> elem(0)
    |> Enum.join()
  end

  defp build_metadata(source, seed) do
    base = %{
      "host" => "#{source}-#{rem(seed, 10) + 1}.internal",
      "pid" => rem(seed * 17, 65_535) + 1024,
      "thread" => "scheduler-#{rem(seed, 8) + 1}",
      "request_id" => uuid_like(seed)
    }

    extra =
      case source do
        "api-gateway" ->
          %{
            "method" => Enum.at(~w(GET POST PUT DELETE), rem(seed, 4)),
            "path" => "/api/v#{rem(seed, 3) + 1}/#{Enum.at(~w(users orders products), rem(seed, 3))}",
            "status" => Enum.at([200, 201, 204, 400, 401, 404, 500], rem(seed, 7)),
            "latency_ms" => rem(seed * 31, 500) + 2
          }

        "payment-worker" ->
          %{
            "provider" => Enum.at(~w(stripe paypal adyen), rem(seed, 3)),
            "amount_cents" => rem(seed * 137, 99_999) + 100,
            "currency" => "USD",
            "idempotency_key" => "ik_#{uuid_like(seed + 1)}"
          }

        "db-replicator" ->
          %{
            "lag_bytes" => rem(seed, 1_048_576),
            "wal_position" => "0/#{rem(seed, 16_777_215)}",
            "replication_slot" => "replica_#{rem(seed, 3) + 1}"
          }

        "rate-limiter" ->
          %{
            "tokens_remaining" => rem(seed, 100),
            "window" => "#{rem(seed, 60) + 1}s",
            "client_id" => "client_#{rem(seed, 500) + 1}"
          }

        "cache-layer" ->
          %{
            "operation" => Enum.at(~w(GET SET DEL EXPIRE), rem(seed, 5)),
            "key" => "cache:#{source}:#{rem(seed, 1000)}",
            "hit" => rem(seed, 3) > 0
          }

        _ -> %{}
      end

    Map.merge(base, extra)
  end

  defp uuid_like(seed) do
    parts =
      for offset <- 0..4 do
        Integer.to_string(rem(seed * (offset + 1) * 7919, 65_536), 16)
        |> String.pad_leading(4, "0")
      end

    tail = Integer.to_string(rem(seed, 4096), 16) |> String.pad_leading(3, "0")
    "#{Enum.at(parts, 0)}#{Enum.at(parts, 1)}-#{Enum.at(parts, 2)}-#{Enum.at(parts, 3)}-#{Enum.at(parts, 4)}#{tail}"
  end
end

Drift.Seed.run()
