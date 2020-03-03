defmodule BattleBox.GameEngine.PlayerServer do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter], restart: :temporary
  alias BattleBox.Lobby
  alias BattleBox.GameEngine.{MatchMaker, GameServer}

  def accept_game(player_server, game_id, timeout \\ 5000) do
    GenStateMachine.call(player_server, {:accept_game, game_id}, timeout)
  end

  def reject_game(player_server, game_id, timeout \\ 5000) do
    GenStateMachine.call(player_server, {:reject_game, game_id}, timeout)
  end

  def match_make(player_server, timeout \\ 5000) do
    GenStateMachine.call(player_server, :match_make, timeout)
  end

  def submit_moves(player_server, move_id, moves, timeout \\ 5000) do
    GenStateMachine.call(player_server, {:submit_moves, move_id, moves}, timeout)
  end

  def start_link(
        %{names: _} = config,
        %{connection: _, player_id: _, user_id: _, lobby_name: _, connection_id: _} = data
      ) do
    data = Map.put_new(data, :player_server_id, Ecto.UUID.generate())

    case Lobby.get_by_name(data.lobby_name) do
      %Lobby{} = lobby ->
        data = Map.put(data, :lobby, lobby)

        GenStateMachine.start_link(__MODULE__, Map.merge(config, data),
          name:
            {:via, Registry,
             {config.names.player_registry, data.player_server_id,
              %{
                player_id: data.player_id,
                lobby_id: lobby.id,
                user_id: data.user_id,
                connection_id: data.connection_id
              }}}
        )

      nil ->
        {:error, :lobby_not_found}
    end
  end

  def init(%{connection: connection} = data) do
    Process.monitor(connection)
    {:ok, :options, data}
  end

  def handle_event(:info, {:DOWN, _, _, pid, _}, _state, %{connection: pid} = data) do
    {:next_state, :disconnected, data}
  end

  def handle_event(:enter, _old_state, :disconnected, _data) do
    {:stop, :normal}
  end

  def handle_event({:call, from}, :match_make, :options, data) do
    :ok = MatchMaker.join_queue(data.names.game_engine, data.lobby.id, data.player_id)
    {:next_state, :match_making, data, {:reply, from, :ok}}
  end

  def handle_event(:info, {:game_request, game_info}, :match_making, data) do
    :ok = MatchMaker.dequeue_self(data.names.game_engine, data.lobby.id)
    {:ok, data} = setup_game(data, game_info)
    {:next_state, :game_acceptance, data}
  end

  def handle_event(:info, {:game_request, game_info}, state, _data) when state != :match_making do
    :ok = GameServer.reject_game(game_info.game_server, game_info.player)
    :keep_state_and_data
  end

  def handle_event(:enter, _old_state, :game_acceptance, data) do
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
      :accept_game ->
        :ok = GameServer.accept_game(game_info.game_server, game_info.player)
        {:next_state, :playing, data, {:reply, from, :ok}}

      :reject_game ->
        :ok = GameServer.reject_game(game_info.game_server, game_info.player)
        {:ok, data} = teardown_game(game_id, data)
        {:next_state, :options, data, {:reply, from, :ok}}
    end
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

  def handle_event(:info, {:moves_request, moves_request}, :playing, data) do
    moves_request = Map.put_new(moves_request, :request_id, Ecto.UUID.generate())
    data = Map.put(data, :moves_request, moves_request)
    {:next_state, :moves_request, data}
  end

  def handle_event(:enter, :playing, :moves_request, %{moves_request: moves_request} = data) do
    send(data.connection, {:moves_request, moves_request})
    {:keep_state, data, {:state_timeout, moves_request.maximum_time, :moves_timeout}}
  end

  def handle_event(
        {:call, from},
        {:submit_moves, id, moves},
        :moves_request,
        %{moves_request: %{request_id: id}} = data
      ) do
    :ok = GameServer.submit_moves(data.game_info.game_server, data.moves_request.player, moves)
    data = Map.drop(data, [:moves_request])
    {:next_state, :playing, data, {:reply, from, :ok}}
  end

  def handle_event({:call, from}, {:submit_moves, _, _}, _, _),
    do: {:keep_state_and_data, {:reply, from, {:error, :invalid_moves_submission}}}

  def handle_event(:state_timemout, :moves_timeout, :moves_request, data) do
    send(data.connection, {:moves_request_timeout, data.moves_request.request_id})
    :ok = GameServer.submit_moves(data.game_info.game_server, data.moves_request.player, [])
    data = Map.drop(data, :moves_request)
    {:next_state, :playing, data}
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

  def handle_event(:enter, _old_state, _state, _data), do: :keep_state_and_data

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
end
