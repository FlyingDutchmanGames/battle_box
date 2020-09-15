defmodule BattleBox.GameEngine.HumanServer do
  alias BattleBox.GameEngine.GameServer
  use GenStateMachine, callback_mode: [:handle_event_function], restart: :temporary
  import :timer, only: [minutes: 1]

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
          human_server_id: Ecto.UUID.generate(),
          ui_pid: nil
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
    if ui_pid = data[:ui_pid], do: Process.monitor(ui_pid)
    {:ok, :awaiting_game_request, data}
  end

  def handle_event({:call, from}, {:connect_ui, _ui_pid}, _state, %{ui_pid: ui_pid})
      when not is_nil(ui_pid) do
    {:keep_state_and_data, {:reply, from, {:error, :already_connected}}}
  end

  def handle_event({:call, from}, {:connect_ui, ui_pid}, state, %{ui_pid: nil} = data) do
    Process.monitor(ui_pid)
    data = Map.put(data, :ui_pid, ui_pid)
    :ok = update_registry(data)

    if state == :awaiting_game_request,
      do: {:keep_state, Map.put(data, :waiting_on_game_request, from)},
      else: {:keep_state, data, {:reply, from, {:ok, on_connect_msg(data)}}}
  end

  def handle_event(:info, {:game_cancelled, game_id}, _state, data) do
    if data.ui_pid, do: send(data.ui_pid, {:game_cancelled, game_id})
    {:stop, :normal}
  end

  def handle_event(:info, {:game_request, game_request}, :awaiting_game_request, data) do
    Process.monitor(game_request.game_server)
    :ok = GameServer.accept_game(game_request.game_server, game_request.player)
    data = Map.put(data, :game_request, game_request)
    :ok = update_registry(data)

    if to = data[:waiting_on_game_request],
      do: {:next_state, :playing, data, {:reply, to, {:ok, on_connect_msg(data)}}},
      else: {:next_state, :playing, data}
  end

  def handle_event(:info, {:commands_request, commands_request} = msg, :playing, data) do
    data = Map.put(data, :commands_request, commands_request)
    if data.ui_pid, do: send(data.ui_pid, msg)
    {:keep_state, data}
  end

  def handle_event(:info, {:game_info, game_info} = msg, :playing, data) do
    data = Map.put(data, :game_info, game_info)
    if data.ui_pid, do: send(data.ui_pid, msg)
    {:keep_state, data}
  end

  def handle_event(:info, {:debug_info, _debug_info} = msg, :playing, data) do
    if data.ui_pid, do: send(data.ui_pid, msg)
    {:keep_state, data}
  end

  def handle_event(:info, {:game_over, _info} = msg, :playing, data) do
    if data.ui_pid, do: send(data.ui_pid, msg)
    {:stop, :normal}
  end

  def handle_event({:call, from}, {:submit_commands, commands}, :playing, data) do
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
    {:keep_state, data}
  end

  defp on_connect_msg(data) do
    %{
      game_request: data[:game_request],
      commands_request: data[:commands_request],
      game_info: data[:game_info]
    }
  end

  defp update_registry(%{names: names} = data) do
    metadata =
      data
      |> Map.take([:ui_pid])
      |> Map.put(:game_id, data[:game_request][:game_id])

    {_, _} =
      Registry.update_value(names.human_registry, data.human_server_id, &Map.merge(&1, metadata))

    :ok
  end
end
