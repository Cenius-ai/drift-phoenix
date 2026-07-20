defmodule Drift.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Drift.Repo
      import Ecto
      import Ecto.Query
      import Drift.DataCase
    end
  end

  setup tags do
    Drift.DataCase.setup_sandbox(tags)
    :ok
  end

  @doc """
  Sets up the sandbox for Ecto tests.
  """
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Drift.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end
