defmodule BattleBox.GameEngine.HumanServer do
  alias BattleBox.GameEngine.GameServer
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter], restart: :temporary
  import :timer, only: [minutes: 1]

  alias BattleBox.GameEngine.Message.{
    CommandsRequest,
    DebugInfo,
    GameInfo,
    GameOver,
    GameRequest,
    GameCanceled
  }

  @default_connection_timeout minutes(5)

  def connect_ui(human_server, pid) do
    GenStateMachine.call(human_server, {:connect_ui, pid})
  end

  def submit_commands(human_server, commands) do
    GenStateMachine.call(human_server, {:submit_commands, commands})
  end

  def start_link(%{names: _} = config, opts) do
    opts =
      Map.merge(
        %{
          connection_timeout: @default_connection_timeout,
          human_server_id: Ecto.UUID.generate()
        },
        opts
      )

    GenStateMachine.start_link(__MODULE__, Map.merge(config, opts),
      name:
        {:via, Registry,
         {config.names.human_registry, opts.human_server_id,
          %{started_at: NaiveDateTime.utc_now()}}}
    )
  end

  def init(data) do
    case data[:ui_pid] do
      nil ->
        {:ok, :disconnected, data}

      pid when is_pid(pid) ->
        Process.monitor(pid)
        {:ok, :connected, data}
    end
  end

  def handle_event(:enter, _old_state, :disconnected, data),
    do: {:keep_state_and_data, {:state_timeout, data.connection_timeout, :disconnection_timeout}}

  def handle_event(:enter, _old_state, :connected, _data), do: :keep_state_and_data

  def handle_event(:state_timeout, :disconnection_timeout, :disconnected, _data) do
    {:stop, :normal}
  end

  def handle_event({:call, from}, {:connect_ui, _ui_pid}, :connected, _data) do
    {:keep_state_and_data, {:reply, from, {:error, :already_connected}}}
  end

  def handle_event({:call, from}, {:connect_ui, ui_pid}, :disconnected, data) do
    Process.monitor(ui_pid)
    data = Map.put(data, :ui_pid, ui_pid)
    :ok = update_registry(data)

    if data[:game_request],
      do: {:next_state, :connected, data, {:reply, from, {:ok, on_connect_msg(data)}}},
      else: {:next_state, :connected, Map.put(data, :waiting_on_game_request, from)}
  end

  def handle_event(:info, %GameCanceled{} = msg, state, %{ui_pid: ui_pid}) do
    if state == :connected, do: send(ui_pid, msg)
    {:stop, :normal}
  end

  def handle_event(:info, %GameRequest{} = game_request, state, data) do
    Process.monitor(game_request.game_server)
    :ok = GameServer.accept_game(game_request.game_server, game_request.player)
    data = Map.put(data, :game_request, game_request)
    :ok = update_registry(data)

    if state == :connected && data[:waiting_on_game_request],
      do:
        {:keep_state, data, {:reply, data[:waiting_on_game_request], {:ok, on_connect_msg(data)}}},
      else: {:keep_state, data}
  end

  def handle_event(:info, %CommandsRequest{} = msg, state, data) do
    data = Map.put(data, :commands_request, msg)
    if state == :connected, do: send(data.ui_pid, msg)
    {:keep_state, data}
  end

  def handle_event(:info, %GameInfo{} = msg, state, data) do
    data = Map.put(data, :game_info, msg)
    if state == :connected, do: send(data.ui_pid, msg)
    {:keep_state, data}
  end

  def handle_event(:info, %DebugInfo{} = msg, state, data) do
    if state == :connected, do: send(data.ui_pid, msg)
    {:keep_state, data}
  end

  def handle_event(:info, %GameOver{} = msg, state, data) do
    if state == :connected, do: send(data.ui_pid, msg)
    {:stop, :normal}
  end

  def handle_event({:call, from}, {:submit_commands, commands}, :connected, data) do
    GameServer.submit_commands(data.game_request.game_server, data.game_request.player, commands)
    data = Map.put(data, :commands_request, nil)
    {:keep_state, data, {:reply, from, :ok}}
  end

  def handle_event(:info, {:DOWN, _, _, game_server, _}, _state, %{
        game_request: %{game_server: game_server}
      }) do
    {:stop, :normal}
  end

  def handle_event(:info, {:DOWN, _, :process, ui_pid, _}, _state, %{ui_pid: ui_pid} = data) do
    data = Map.put(data, :ui_pid, nil)
    {:next_state, :disconnected, data}
  end

  defp on_connect_msg(data) do
    %{
      game_request: data[:game_request],
      commands_request: data[:commands_request],
      game_info: data[:game_info]
    }
  end

  defp update_registry(%{names: names} = data) do
    game_id =
      case data do
        %{game_request: %{game_id: game_id}} -> game_id
        _ -> nil
      end

    metadata =
      data
      |> Map.take([:ui_pid])
      |> Map.put(:game_id, game_id)

    {_, _} =
      Registry.update_value(names.human_registry, data.human_server_id, &Map.merge(&1, metadata))

    :ok
  end
end
