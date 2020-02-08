defmodule BattleBox.PlayerServer do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter], restart: :temporary
  alias BattleBox.{Lobby, MatchMaker, GameServer}

  def join_lobby(player_server, lobby_name, timeout \\ 5000) do
    GenStateMachine.call(player_server, {:join_lobby, %{lobby_name: lobby_name}}, timeout)
  end

  def start_link(%{names: _} = config, %{connection: _, player_id: _} = data) do
    data = Map.put_new(data, :player_server_id, Ecto.UUID.generate())
    GenStateMachine.start_link(__MODULE__, Map.merge(config, data))
  end

  def init(%{names: names} = data) do
    connection_monitor = Process.monitor(data.connection)

    Registry.register(names.player_registry, data.player_server_id, %{player_id: data.player_id})

    data = Map.merge(data, %{connection_monitor: connection_monitor})

    {:ok, :options, data}
  end

  def handle_event(
        :info,
        {:DOWN, connection_monitor, _, _, _},
        _state,
        %{connection_monitor: connection_monitor} = data
      ) do
    {:next_state, :disconnected, data}
  end

  def handle_event(:enter, _, state, data) when state in [:options],
    do: {:next_state, state, data}

  def handle_event({:call, from}, {:join_lobby, %{lobby_name: lobby_name}}, :options, data) do
    case Lobby.get_by_name(lobby_name) do
      %Lobby{} = lobby ->
        :ok = MatchMaker.join_queue(data.names.game_engine, lobby.id, data.player_id)
        data = Map.put(data, :lobby, lobby)
        {:next_state, :match_making, data, [{:reply, from, :ok}]}

      nil ->
        {:keep_state, data, [{:reply, from, {:error, :lobby_not_found}}]}
    end
  end

  def handle_event(:enter, _old_state, :match_making, _data) do
    :keep_state_and_data
  end

  def handle_event(:info, {:game_request, game_info} = msg, :match_making, data) do
    send(data.connection, msg)

    game_monitor = Process.monitor(game_info.game_server)
    :ok = MatchMaker.dequeue_self(data.names.game_engine, data.lobby.id)

    data =
      Map.merge(data, %{
        game_monitor: game_monitor,
        game_info: game_info
      })

    {:next_state, :game_acceptance, data}
  end

  def handle_event(:enter, _old_state, :game_acceptance, data) do
    {:keep_state, data,
     [{:state_timeout, data.lobby.game_acceptance_timeout_ms, :game_acceptance_timeout}]}
  end

  def handle_event(
        :info,
        {:accept_game, game_id},
        :game_acceptance,
        %{game_info: %{game_id: game_id, game_server: game_server, player: player}} = data
      ) do
    :ok = GameServer.accept_game(game_server, player)
    {:next_state, :playing, data}
  end

  def handle_event(
        :info,
        {:reject_game, game_id},
        :game_acceptance,
        %{game_id: %{game_id: game_id, game_server: game_server, player: player}} = data
      ) do
    :ok = GameServer.reject_game(game_server, player)
    {:next_state, :options, data}
  end

  def handle_event(
        :info,
        {:DOWN, game_monitor, _, _, _},
        :game_acceptance,
        %{game_monitor: game_monitor} = data
      ) do
    send(data.connection, {:game_cancelled, data.game_info.game_id})
    {:next_state, :options, data}
  end

  def handle_event(
        :info,
        {:game_cancelled, game_id} = msg,
        :game_acceptance,
        %{game_info: %{game_id: game_id}} = data
      ) do
    send(data.connection, msg)
    {:next_state, :options, data}
  end

  def handle_event(:enter, :game_acceptance, :disconnected, data) do
    :ok = GameServer.reject_game(data.game_info.game_server, data.game_info.player)
    {:stop, :normal}
  end

  def handle_event(:state_timeout, :game_acceptance_timeout, :game_acceptance, data) do
    :ok = GameServer.reject_game(data.game_info.game_server, data.game_info.player)
    send(data.connection, {:game_acceptance_timeout, data.game_info.game_id})
    {:next_state, :options, data}
  end

  # {:moves_request,
  #  %{
  #    game_id: Game.id(game),
  #    game_state: Game.moves_request(game),
  #    turn: Game.turn(game),
  #    player: player
  #  }}
end
