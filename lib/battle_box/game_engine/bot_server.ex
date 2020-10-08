defmodule BattleBox.GameEngine.BotServer do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter], restart: :temporary
  alias BattleBox.{Arena, GameEngine, GameEngine.GameServer}

  alias BattleBox.GameEngine.Message.{
    CommandsRequest,
    DebugInfo,
    GameInfo,
    GameOver,
    GameRequest,
    GameCanceled
  }

  def accept_game(bot_server, game_id, timeout \\ 5000) do
    GenStateMachine.call(bot_server, {:accept_game, game_id}, timeout)
  end

  def reject_game(bot_server, game_id, timeout \\ 5000) do
    GenStateMachine.call(bot_server, {:reject_game, game_id}, timeout)
  end

  def match_make(bot_server, %Arena{} = arena, timeout \\ 5000) do
    GenStateMachine.call(bot_server, {:match_make, arena}, timeout)
  end

  def practice(bot_server, %Arena{} = arena, opponent, timeout \\ 5000) do
    GenStateMachine.call(bot_server, {:practice, arena, opponent}, timeout)
  end

  def submit_commands(bot_server, command_id, commands, timeout \\ 5000) do
    GenStateMachine.call(bot_server, {:submit_commands, command_id, commands}, timeout)
  end

  def start_link(
        %{names: _} = config,
        %{connection: _, bot: bot} = data
      ) do
    data = Map.put_new(data, :bot_server_id, Ecto.UUID.generate())

    GenStateMachine.start_link(__MODULE__, Map.merge(config, data),
      name:
        {:via, Registry,
         {config.names.bot_registry, data.bot_server_id,
          %{bot: bot, game_id: nil, started_at: NaiveDateTime.utc_now()}}}
    )
  end

  def init(%{connection: connection} = data) do
    :ok =
      GameEngine.broadcast_bot_server_start(
        data.names.game_engine,
        Map.take(data, [:bot, :bot_server_id])
      )

    Process.monitor(connection)
    {:ok, :options, data}
  end

  def handle_event(:info, {:DOWN, _, _, pid, _}, _state, %{connection: pid}) do
    {:stop, :normal}
  end

  def handle_event({:call, from}, {:match_make, arena}, :options, data) do
    :ok = GameEngine.join_queue(data.names.game_engine, arena.id, data.bot)
    {:next_state, :match_making, data, {:reply, from, :ok}}
  end

  def handle_event({:call, from}, {:practice, arena, opponent}, :options, data) do
    case GameEngine.practice_match(data.names.game_engine, arena, data.bot, opponent) do
      {:ok, _meta} ->
        {:next_state, :match_making, data, {:reply, from, :ok}}

      {:error, :no_opponent_matching} = err ->
        {:keep_state_and_data, {:reply, from, err}}
    end
  end

  def handle_event(:info, %GameRequest{} = game_info, :match_making, data) do
    :ok = GameEngine.dequeue_self(data.names.game_engine)
    {:ok, data} = setup_game(data, game_info)
    {:next_state, :game_acceptance, data, {:next_event, :internal, :setup_game_acceptance}}
  end

  def handle_event(:info, %GameRequest{} = game_info, state, _data) when state != :match_making do
    :ok = GameServer.reject_game(game_info.game_server, game_info.player)
    :keep_state_and_data
  end

  def handle_event(:internal, :setup_game_acceptance, :game_acceptance, data) do
    {:keep_state, data, [{:state_timeout, data.game_info.accept_time, :game_acceptance_timeout}]}
  end

  def handle_event(
        {:call, from},
        {response, game_id},
        :game_acceptance,
        %{game_info: %{game_id: game_id} = game_info} = data
      )
      when response in [:accept_game, :reject_game] do
    case response do
      :accept_game -> :ok = GameServer.accept_game(game_info.game_server, game_info.player)
      :reject_game -> :ok = GameServer.reject_game(game_info.game_server, game_info.player)
    end

    {:next_state, :playing, data, {:reply, from, :ok}}
  end

  def handle_event({:call, from}, {response, _game_id}, _state, _data)
      when response in [:accept_game, :reject_game],
      do: {:keep_state_and_data, {:reply, from, :ok}}

  def handle_event(:state_timeout, :game_acceptance_timeout, :game_acceptance, data) do
    :ok = GameServer.reject_game(data.game_info.game_server, data.game_info.player)
    {:next_state, :options, data}
  end

  def handle_event(
        :info,
        {:DOWN, _, _, pid, _},
        _state,
        %{game_info: %{game_server: pid}} = data
      ) do
    send(data.connection, %GameCanceled{game_id: data.game_info.game_id})
    {:ok, data} = teardown_game(data.game_info.game_id, data)
    {:next_state, :options, data, cancel_move_timeout_actions()}
  end

  def handle_event(
        :info,
        %GameCanceled{game_id: id} = msg,
        _,
        %{game_info: %{game_id: id}} = data
      ) do
    send(data.connection, msg)
    {:ok, data} = teardown_game(id, data)
    {:next_state, :options, data, cancel_move_timeout_actions()}
  end

  def handle_event(:info, %GameCanceled{}, _state, _data), do: :keep_state_and_data

  def handle_event(:info, %CommandsRequest{} = commands_request, :playing, data) do
    data = Map.put(data, :commands_request, commands_request)
    {:next_state, :commands_request, data, {:next_event, :internal, :setup_commands_request}}
  end

  def handle_event(:info, %GameInfo{} = msg, _state, data) do
    send(data.connection, msg)
    :keep_state_and_data
  end

  def handle_event(:info, %DebugInfo{} = msg, _state, data) do
    send(data.connection, msg)
    :keep_state_and_data
  end

  def handle_event(
        :internal,
        :setup_commands_request,
        :commands_request,
        %{commands_request: commands_request} = data
      ) do
    send(data.connection, commands_request)
    data = Map.put(data, :min_time_met, false)

    {:keep_state, data,
     move_timeout_actions(commands_request.minimum_time, commands_request.maximum_time)}
  end

  def handle_event(
        {:call, from},
        {:submit_commands, id, commands},
        :commands_request,
        %{commands_request: %{request_id: id}} = data
      ) do
    if data[:min_time_met] do
      data = submit_commands_to_game_server(data, commands)

      {:next_state, :playing, data, [{:reply, from, :ok} | cancel_move_timeout_actions()]}
    else
      {:keep_state, Map.put(data, :commands, commands), {:reply, from, :ok}}
    end
  end

  def handle_event(
        {:timeout, :min_time},
        :min_time,
        :commands_request,
        %{commands: commands} = data
      ) do
    data = submit_commands_to_game_server(data, commands)
    {:next_state, :playing, data, cancel_move_timeout_actions()}
  end

  def handle_event({:timeout, :min_time}, :min_time, :commands_request, data) do
    {:keep_state, Map.put(data, :min_time_met, true)}
  end

  def handle_event({:timeout, :max_time}, :max_time, :commands_request, data) do
    data = submit_commands_to_game_server(data, :timeout)
    {:next_state, :playing, data}
  end

  def handle_event({:call, from}, {:submit_commands, _, _}, _, _),
    do: {:keep_state_and_data, {:reply, from, {:error, :invalid_commands_submission}}}

  def handle_event(:enter, _old_state, new_state, %{names: names} = data) do
    game_id =
      case data do
        %{game_info: %{game_id: id}} -> id
        _ -> nil
      end

    {_, _} =
      Registry.update_value(
        names.bot_registry,
        data.bot_server_id,
        &Map.merge(&1, %{
          status: new_state,
          game_id: game_id
        })
      )

    :ok =
      GameEngine.broadcast_bot_server_update(
        names.game_engine,
        Map.take(data, [:bot, :bot_server_id])
      )

    :keep_state_and_data
  end

  def handle_event(
        :info,
        %GameOver{game_id: game_id} = msg,
        _state,
        %{game_info: %{game_id: game_id}} = data
      ) do
    {:ok, data} = teardown_game(game_id, data)
    send(data.connection, msg)
    {:next_state, :options, data, cancel_move_timeout_actions()}
  end

  defp setup_game(data, game_info) do
    game_monitor = Process.monitor(game_info.game_server)
    send(data.connection, game_info)
    data = Map.merge(data, %{game_info: game_info, game_monitor: game_monitor})
    {:ok, data}
  end

  defp teardown_game(game_id, %{game_info: %{game_id: game_id}} = data) do
    Process.demonitor(data.game_monitor, [:flush])
    data = Map.drop(data, [:game_info, :game_monitor])
    {:ok, data}
  end

  defp teardown_game(_game_id, data), do: {:ok, data}

  defp submit_commands_to_game_server(data, commands) do
    :ok =
      GameServer.submit_commands(
        data.game_info.game_server,
        data.commands_request.player,
        commands
      )

    Map.drop(data, [:commands, :commands_request, :min_time_met])
  end

  defp move_timeout_actions(min_time, max_time) do
    [
      {{:timeout, :min_time}, min_time, :min_time},
      {{:timeout, :max_time}, max_time, :max_time}
    ]
  end

  defp cancel_move_timeout_actions do
    [
      {{:timeout, :min_time}, :cancel},
      {{:timeout, :max_time}, :cancel}
    ]
  end
end
