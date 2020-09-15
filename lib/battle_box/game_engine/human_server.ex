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
    {:ok, :awaiting_game_request, data}
  end

  def handle_event(
        {:call, from},
        {:connect_ui, ui_pid},
        :awaiting_game_request,
        %{ui_pid: nil} = data
      ) do
    data = Map.put(data, :pending_connect_ui, {from, ui_pid})
    {:keep_state, data}
  end

  def handle_event({:call, from}, {:connect_ui, _ui_pid}, _state, %{ui_pid: ui_pid})
      when not is_nil(ui_pid) do
    {:keep_state_and_data, {:reply, from, {:error, :already_connected}}}
  end

  def handle_event({:call, from}, {:connect_ui, ui_pid}, state, %{ui_pid: nil} = data) do
    Process.monitor(ui_pid)
    data = Map.put(data, :ui_pid, ui_pid)
    :ok = update_registry(data)
    {:keep_state, data, {:reply, from, {:ok, on_connect_msg(data)}}}
  end

  def handle_event(:info, {:game_cancelled, game_id}, _state, data) do
    if data.ui_pid, do: send(data.ui_pid, {:game_cancelled, game_id})
    {:stop, :normal}
  end

  def handle_event(
        :info,
        {:game_request, game_request},
        :awaiting_game_request,
        %{pending_connect_ui: {from, ui_pid}} = data
      ) do
    Process.monitor(game_request.game_server)
    :ok = GameServer.accept_game(game_request.game_server, game_request.player)
    data = Map.put(data, :game_request, game_request)
    :ok = update_registry(data)
    {:next_state, :playing, data, {:reply, from, {:ok, on_connect_msg(data)}}}
  end

  def handle_event(:info, {:game_request, game_request}, :awaiting_game_request, data) do
    Process.monitor(game_request.game_server)
    :ok = GameServer.accept_game(game_request.game_server, game_request.player)
    data = Map.put(data, :game_request, game_request)
    :ok = update_registry(data)
    {:next_state, :playing, data}
  end

  def handle_event(
        :info,
        {:DOWN, _, _, game_server, _},
        state,
        %{game_request: %{game_server: game_server}} = data
      ) do
    {:stop, :normal}
  end

  defp on_connect_msg(data) do
    %{
      game_request: data[:game_request],
      commands_request: data[:commands_request]
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
