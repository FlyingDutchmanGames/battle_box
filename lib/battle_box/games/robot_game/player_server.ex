defmodule BattleBox.Games.RobotGame.PlayerServer do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  def request_matchmaking(server) do
    GenStateMachine.call(server, :matchmake)
  end

  def start_link(config, %{connection: conn} = data) when is_pid(conn) do
    server_id = Ecto.UUID.generate()

    data =
      data
      |> Map.put(:server_id, server_id)
      |> Map.merge(config)

    GenStateMachine.start_link(__MODULE__, data)
  end

  def init(%{connection: conn} = data) do
    ref = Process.monitor(conn)
    data = Map.put(data, :conn_ref, ref)
    {:ok, :options, data}
  end

  def handle_event(:info, {:DOWN, ref, :process, _, _}, _state, %{conn_ref: ref} = data) do
    {:next_state, :disconnected, data}
  end

  def handle_event(:enter, _old_state, :disconnected, data) do
    # TODO:// handle timeout of disconnected
    {:keep_state, data, []}
  end

  def handle_event(:enter, _old_state, :options, data) do
    send(data.connection, options())
    {:keep_state, data}
  end

  def handle_event({:call, from}, :matchmake, :options, data) do
    {:next_state, :matchmaking, data, [{:reply, from, :ok}]}
  end

  def handle_event(:enter, _old_state, :matchmaking, data) do
    {:keep_state, data}
  end

  defp options() do
    {:options, [:matchmaking]}
  end
end
