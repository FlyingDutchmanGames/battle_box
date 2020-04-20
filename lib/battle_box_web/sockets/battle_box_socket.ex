defmodule BattleBoxWeb.BattleBoxSocket do
  @behaviour Phoenix.Socket.Transport

  def child_spec(opts) do
    # We won't spawn any process, so let's return a dummy task
    # Also, why the heck does it require you to spawn a dummy task ?!?!
    %{id: Task, start: {Task, :start_link, [fn -> :ok end]}, restart: :transient}
  end

  def connect(state) do
    {:ok, state}
  end

  def init(state) do
    {:ok, state}
  end

  def handle_in({"ping", _opts}, state) do
    {:reply, :ok, {:text, "pong"}, state}
  end

  def handle_info(msg, state) do
    {:ok, state}
  end

  def terminate(reason, _state) do
    :ok
  end
end
