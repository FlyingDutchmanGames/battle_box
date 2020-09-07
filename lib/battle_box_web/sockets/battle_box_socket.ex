defmodule BattleBoxWeb.Sockets.BattleBoxSocket do
  import BattleBox.GameEngine.Provider, only: [game_engine: 0]
  import DateTime, only: [utc_now: 0]
  alias BattleBox.GameEngine
  alias BattleBox.Connection.Logic
  import BattleBox.Connection.Message

  @behaviour Phoenix.Socket.Transport

  def child_spec(_opts) do
    # We won't spawn any process, so let's return a dummy task
    # Also, why the heck does it require you to spawn a dummy task ?!?!
    %{id: Task, start: {Task, :start_link, [fn -> :ok end]}, restart: :transient}
  end

  def connect(data) do
    {:ok, data}
  end

  def init(data) do
    data =
      data
      |> Map.put_new(:connection_id, Ecto.UUID.generate())
      |> Map.put(:names, GameEngine.names(game_engine()))
      |> Logic.init()

    {:ok, _} =
      Registry.register(data.names.connection_registry, data.connection_id, %{
        started_at: utc_now()
      })

    {:ok, data}
  end

  def handle_in({"ping", _opts}, data) do
    {:reply, :ok, {:text, "pong"}, data}
  end

  def handle_in({bytes, _opts}, data) do
    case Jason.decode(bytes) do
      {:ok, msg} ->
        handle_msg({:client, msg}, data)

      {:error, %Jason.DecodeError{}} ->
        {:reply, :ok, {:text, encode_error("invalid_json")}, data}
    end
  end

  def handle_info({:stop, reason}, data), do: {:stop, reason, data}
  def handle_info(msg, data), do: handle_msg({:system, msg}, data)

  def terminate(reason, _data) do
    :ok
  end

  defp handle_msg(msg, data) do
    {data, actions, continue?} = Logic.handle_message(msg, data)

    for {:monitor, pid} <- actions,
        do: Process.monitor(pid)

    if continue? == :stop,
      do: send(self(), {:stop, :normal})

    if actions[:send],
      do: {:reply, :ok, {:text, actions[:send]}, data},
      else: {:ok, data}
  end
end
