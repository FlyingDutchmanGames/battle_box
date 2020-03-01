defmodule BattleBox.GameEngine.GameServer do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter], restart: :temporary
  alias BattleBoxGame
  alias BattleBox.{Game, GameEngine}

  def accept_game(game_server, player) when is_binary(player) do
    GenStateMachine.cast(game_server, {:accept_game, player})
  end

  def reject_game(game_server, player) when is_binary(player) do
    GenStateMachine.cast(game_server, {:reject_game, player})
  end

  def forfeit_game(game_server, player) when is_binary(player) do
    GenStateMachine.cast(game_server, {:forfeit_game, player})
  end

  def submit_moves(game_server, player, moves) when is_binary(player) do
    GenStateMachine.cast(game_server, {:moves, player, moves})
  end

  def start_link(config, %{players: players, game: game} = data) do
    GenStateMachine.start_link(__MODULE__, Map.merge(config, data),
      name: {:via, Registry, {config.names.game_registry, game.id, initial_metadata(game)}}
    )
  end

  def init(data) do
    {:ok, :game_acceptance, data, {:next_event, :internal, :setup}}
  end

  def handle_event(:internal, :setup, :game_acceptance, data) do
    for {player, pid} <- data.players do
      Process.monitor(pid)
      send(pid, init_message(data.game, player))
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
    for {_player, pid} <- data.players do
      send(pid, {:game_cancelled, data.game.id})
    end

    {:stop, :normal}
  end

  def handle_event(:info, {:DOWN, _, :process, _pid, _}, :game_acceptance, data) do
    for {_player, pid} <- data.players do
      send(pid, {:game_cancelled, data.game.id})
    end

    {:stop, :normal}
  end

  def handle_event(:internal, :collect_moves, :moves, data) do
    for {player, pid} <- data.players do
      send(pid, moves_request(data.game, player))
    end

    {:keep_state, Map.put(data, :moves, [])}
  end

  def handle_event(:cast, {:moves, player, moves}, :moves, data) do
    case data.moves do
      [] ->
        {:keep_state, put_in(data.moves, [{player, moves}])}

      [{other_player, _}] when other_player != player ->
        moves = Map.new([{player, moves} | data.moves])
        data = update_in(data.game.robot_game, &BattleBoxGame.calculate_turn(&1, moves))

        if BattleBoxGame.over?(data.game.robot_game),
          do: {:keep_state, data, {:next_event, :internal, :finalize}},
          else: {:repeat_state, data, {:next_event, :internal, :collect_moves}}
    end
  end

  def handle_event(:cast, {:forfeit_game, player}, :moves, data) do
    {:keep_state, update_in(data.game.robot_game, &BattleBoxGame.disqualify(&1, player)),
     {:next_event, :internal, :finalize}}
  end

  def handle_event(:info, {:DOWN, _, :process, pid, _}, :moves, data) do
    {player, _} = Enum.find(data.players, fn {_player, player_pid} -> player_pid == pid end)

    {:keep_state, update_in(data.game.robot_game, &BattleBoxGame.disqualify(&1, player)),
     {:next_event, :internal, :finalize}}
  end

  def handle_event(:internal, :finalize, _state, %{game: game} = data) do
    {:ok, game} = Game.persist(game)

    for {_player, pid} <- data.players do
      send(pid, game_over_message(game))
    end

    {:stop, :normal}
  end

  def handle_event(:enter, _, new_state, %{names: names, game: game}) do
    metadata = %{status: new_state, game: game}

    {_, _} = Registry.update_value(names.game_registry, game.id, &Map.merge(&1, metadata))

    :ok = GameEngine.broadcast(names.game_engine, "game:#{game.id}", {:game_update, game.id})

    :keep_state_and_data
  end

  defp moves_request(game, player) do
    {:moves_request,
     %{
       game_id: game.id,
       game_state: BattleBoxGame.moves_request(game.robot_game),
       time: BattleBoxGame.move_time_ms(game.robot_game),
       player: player
     }}
  end

  defp init_message(game, player) do
    {:game_request,
     %{
       game_server: self(),
       game_id: game.id,
       player: player,
       settings: BattleBoxGame.settings(game.robot_game)
     }}
  end

  def game_over_message(game) do
    {:game_over,
     %{
       game_id: game.id,
       score: BattleBoxGame.score(game.robot_game),
       winner: BattleBoxGame.winner(game.robot_game)
     }}
  end

  defp initial_metadata(game),
    do: %{
      started_at: DateTime.utc_now(),
      game: game
    }
end
