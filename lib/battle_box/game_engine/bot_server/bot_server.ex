defmodule BattleBox.GameEngine.BotServer do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter], restart: :temporary
  alias BattleBox.{GameEngine, GameEngine.MatchMaker, GameEngine.GameServer}

  def accept_game(bot_server, game_id, timeout \\ 5000) do
    GenStateMachine.call(bot_server, {:accept_game, game_id}, timeout)
  end

  def reject_game(bot_server, game_id, timeout \\ 5000) do
    GenStateMachine.call(bot_server, {:reject_game, game_id}, timeout)
  end

  def match_make(bot_server, timeout \\ 5000) do
    GenStateMachine.call(bot_server, :match_make, timeout)
  end

  def submit_commands(bot_server, command_id, commands, timeout \\ 5000) do
    GenStateMachine.call(bot_server, {:submit_commands, command_id, commands}, timeout)
  end

  def start_link(
        %{names: _} = config,
        %{connection: _, bot: bot, lobby: lobby} = data
      ) do
    data = Map.put_new(data, :bot_server_id, Ecto.UUID.generate())

    GenStateMachine.start_link(__MODULE__, Map.merge(config, data),
      name:
        {:via, Registry,
         {config.names.bot_registry, data.bot_server_id, %{bot: bot, lobby: lobby, game_id: nil}}}
    )
  end

  def init(%{connection: connection} = data) do
    :ok =
      GameEngine.broadcast_bot_server_start(
        data.names.game_engine,
        Map.take(data, [:bot, :lobby, :bot_server_id])
      )

    Process.monitor(connection)
    {:ok, :options, data}
  end

  def handle_event(:info, {:DOWN, _, _, pid, _}, _state, %{connection: pid}) do
    {:stop, :normal}
  end

  def handle_event({:call, from}, :match_make, :options, data) do
    :ok = MatchMaker.join_queue(data.names.game_engine, data.lobby.id, data.bot)
    {:next_state, :match_making, data, {:reply, from, :ok}}
  end

  def handle_event(:info, {:game_request, game_info}, :match_making, data) do
    :ok = MatchMaker.dequeue_self(data.names.game_engine, data.lobby.id)
    {:ok, data} = setup_game(data, game_info)
    {:next_state, :game_acceptance, data, {:next_event, :internal, :setup_game_acceptance}}
  end

  def handle_event(:info, {:game_request, game_info}, state, _data) when state != :match_making do
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
    send(data.connection, {:game_cancelled, data.game_info.game_id})
    {:ok, data} = teardown_game(data.game_info.game_id, data)
    {:next_state, :options, data}
  end

  def handle_event(:info, {:game_cancelled, id} = msg, _, %{game_info: %{game_id: id}} = data) do
    send(data.connection, msg)
    {:ok, data} = teardown_game(id, data)
    {:next_state, :options, data}
  end

  def handle_event(:info, {:game_cancelled, _id}, _state, _data), do: :keep_state_and_data

  def handle_event(:info, {:commands_request, commands_request}, :playing, data) do
    commands_request = Map.put_new(commands_request, :request_id, Ecto.UUID.generate())
    data = Map.put(data, :commands_request, commands_request)
    {:next_state, :commands_request, data, {:next_event, :internal, :setup_commands_request}}
  end

  def handle_event(
        :internal,
        :setup_commands_request,
        :commands_request,
        %{commands_request: commands_request} = data
      ) do
    send(data.connection, {:commands_request, commands_request})
    data = Map.put(data, :min_time_met, false)

    {:keep_state, data,
     [
       {{:timeout, :min_time}, commands_request.minimum_time, :min_time},
       {{:timeout, :max_time}, commands_request.maximum_time, :max_time}
     ]}
  end

  def handle_event(
        {:call, from},
        {:submit_commands, id, commands},
        :commands_request,
        %{commands_request: %{request_id: id}} = data
      ) do
    if data[:min_time_met] do
      data = submit_commands_to_game_server(data, commands)

      {:next_state, :playing, data,
       [
         {:reply, from, :ok},
         {{:timeout, :min_time}, :cancel},
         {{:timeout, :max_time}, :cancel}
       ]}
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
    {:next_state, :playing, data, {{:timeout, :max_time}, :cancel}}
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
    metadata = %{status: new_state, game_id: data[:game_info][:game_id]}

    {_, _} =
      Registry.update_value(names.bot_registry, data.bot_server_id, &Map.merge(&1, metadata))

    :ok =
      GameEngine.broadcast_bot_server_update(
        names.game_engine,
        Map.take(data, [:bot, :lobby, :bot_server_id])
      )

    :keep_state_and_data
  end

  def handle_event(
        :info,
        {:game_over, %{game_id: game_id}} = msg,
        _state,
        %{game_info: %{game_id: game_id}} = data
      ) do
    {:ok, data} = teardown_game(game_id, data)
    send(data.connection, msg)
    {:next_state, :options, data}
  end

  defp setup_game(data, game_info) do
    game_monitor = Process.monitor(game_info.game_server)
    send(data.connection, {:game_request, game_info})
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
end
