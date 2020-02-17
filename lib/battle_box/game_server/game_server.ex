defmodule BattleBox.GameServer do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter], restart: :temporary
  alias BattleBoxGame, as: Game

  def accept_game(game_server, player) do
    GenStateMachine.cast(game_server, {:accept_game, player})
  end

  def reject_game(game_server, player) do
    GenStateMachine.cast(game_server, {:reject_game, player})
  end

  def forfeit_game(game_server, player) do
    GenStateMachine.cast(game_server, {:forfeit_game, player})
  end

  def submit_moves(game_server, player, moves) do
    GenStateMachine.cast(game_server, {:moves, player, moves})
  end

  def start_link(config, %{player_1: _, player_2: _, game: %{id: id} = game} = data) do
    GenStateMachine.start_link(__MODULE__, Map.merge(config, data),
      name: {:via, Registry, {config.names.game_registry, id, initial_metadata(game)}}
    )
  end

  def init(data) do
    {:ok, :game_acceptance, data, {:next_event, :internal, :setup}}
  end

  def handle_event(:internal, :setup, :game_acceptance, data) do
    for player <- [:player_1, :player_2] do
      Process.monitor(data[player])
      send(data[player], init_message(data.game, player))
    end

    {:keep_state, Map.put(data, :acceptances, [])}
  end

  def handle_event(:cast, {:accept_game, player}, :game_acceptance, data) do
    case data.acceptances do
      [] -> {:keep_state, put_in(data.acceptances, [player])}
      [_first_acceptance] -> {:next_state, :moves, data, {:next_event, :internal, :collect_moves}}
    end
  end

  def handle_event(:cast, {:reject_game, _player}, :game_acceptance, data) do
    for player <- [:player_1, :player_2] do
      send(data[player], {:game_cancelled, Game.id(data.game)})
    end

    {:stop, :normal}
  end

  def handle_event(:info, {:DOWN, _, :process, _pid, _}, :game_acceptance, data) do
    for player <- [:player_1, :player_2] do
      send(data[player], {:game_cancelled, Game.id(data.game)})
    end

    {:stop, :normal}
  end

  def handle_event(:internal, :collect_moves, :moves, data) do
    for player <- [:player_1, :player_2] do
      send(data[player], moves_request(data.game, player))
    end

    {:keep_state, Map.put(data, :moves, [])}
  end

  def handle_event(:cast, {:moves, player, moves}, :moves, data) do
    case data.moves do
      [] ->
        {:keep_state, put_in(data.moves, [{player, moves}])}

      [{other_player, _}] when other_player != player ->
        moves = Map.new([{player, moves} | data.moves])
        data = update_in(data.game, &Game.calculate_turn(&1, moves))

        if Game.over?(data.game),
          do: {:keep_state, data, {:next_event, :internal, :finalize}},
          else: {:repeat_state, data, {:next_event, :internal, :collect_moves}}
    end
  end

  def handle_event(:cast, {:forfeit_game, player}, :moves, data) do
    {:keep_state, update_in(data.game, &Game.disqualify(&1, player)),
     {:next_event, :internal, :finalize}}
  end

  def handle_event(:info, {:DOWN, _, :process, pid, _}, :moves, data) do
    player =
      cond do
        pid == data.player_1 -> :player_1
        pid == data.player_2 -> :player_2
      end

    {:keep_state, update_in(data.game, &Game.disqualify(&1, player)),
     {:next_event, :internal, :finalize}}
  end

  def handle_event(:internal, :finalize, _state, %{game: game} = data) do
    {:ok, game} = Game.persist(game)

    for player <- [:player_1, :player_2] do
      send(data[player], game_over_message(game))
    end

    {:stop, :normal}
  end

  def handle_event(:enter, _, new_state, %{names: names, game: game} = data) do
    metadata = %{status: new_state, game: data.game}
    {_, _} = Registry.update_value(names.game_registry, game.id, &Map.merge(&1, metadata))
    :keep_state_and_data
  end

  defp moves_request(game, player) do
    {:moves_request,
     %{
       game_id: Game.id(game),
       game_state: Game.moves_request(game),
       time: Game.move_time_ms(game),
       player: player
     }}
  end

  defp init_message(game, player) do
    {:game_request,
     %{
       game_server: self(),
       game_id: Game.id(game),
       player: player,
       settings: Game.settings(game)
     }}
  end

  def game_over_message(game) do
    {:game_over,
     %{
       game_id: Game.id(game),
       winner: Game.winner(game)
     }}
  end

  defp initial_metadata(game),
    do: %{
      started_at: DateTime.utc_now(),
      game_type: game.__struct__,
      game: game
    }
end
