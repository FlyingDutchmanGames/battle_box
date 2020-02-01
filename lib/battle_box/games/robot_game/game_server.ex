defmodule BattleBox.Games.RobotGame.GameServer do
  alias BattleBox.Games.RobotGame.{Game, Game.Logic}
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]

  def accept_game(game_server, player) do
    GenStateMachine.cast(game_server, {:accept_game, player})
  end

  def reject_game(game_server, player) do
    GenStateMachine.cast(game_server, {:reject_game, player})
  end

  def forfeit_game(game_server, player) do
    GenStateMachine.cast(game_server, {:forfeit_game, player})
  end

  def submit_moves(game_server, player, turn, moves) do
    GenStateMachine.cast(game_server, {:moves, player, turn, moves})
  end

  def start_link(%{player_1: _, player_2: _, game: _} = data) do
    GenStateMachine.start_link(__MODULE__, data)
  end

  def init(data) do
    {:ok, :game_acceptance, data, []}
  end

  def game_acceptance(:enter, _old_state, %{game: game} = data) do
    for player <- [:player_1, :player_2] do
      send(data[player], init_message(data.game, player))
    end

    {:keep_state, Map.put(data, :acceptances, [])}
  end

  def game_acceptance(:cast, {:accept_game, player}, data) do
    case data.acceptances do
      [] -> {:keep_state, put_in(data.acceptances, [player])}
      [_first_acceptance] -> {:next_state, :moves, data}
    end
  end

  def game_acceptance(:cast, {:reject_game, player}, data) do
    for player <- [:player_1, :player_2] do
      send(data[player], {:game_cancelled, data.game.id})
    end

    {:stop, :normal}
  end

  def moves(:enter, _old_state, data) do
    for player <- [:player_1, :player_2] do
      send(data[player], moves_request(data.game, player))
    end

    {:keep_state, Map.put(data, :moves, [])}
  end

  def moves(:cast, {:moves, player, _turn, moves}, data) do
    case data.moves do
      [] ->
        {:keep_state, put_in(data.moves, [{player, moves}])}

      [{other_player, other_moves}] when other_player != player ->
        moves = Enum.concat(moves, other_moves)
        data = update_in(data.game, &Logic.calculate_turn(&1, moves))

        if Game.over?(data.game),
          do: {:next_state, :finalize, data},
          else: {:repeat_state, data}
    end
  end

  def moves(:cast, {:forfeit_game, player}, data) do
    {:next_state, :finalize, update_in(data.game, &Game.disqualify(&1, player))}
  end

  def finalize(:enter, :moves, %{game: game} = data) do
    {:ok, game} = Game.persist(game)

    for player <- [:player_1, :player_2] do
      send(data[player], game_over_message(game))
    end

    {:stop, :normal}
  end

  defp moves_request(game, player) do
    {:moves_request,
     %{
       game_id: game.id,
       robots: Game.robots(game),
       turn: game.turn,
       player: player
     }}
  end

  defp init_message(game, player) do
    {:game_request,
     %{
       game_server: self(),
       game_id: game.id,
       player: player,
       settings:
         Map.take(game, [
           :spawn_every,
           :spawn_per_player,
           :robot_hp,
           :attack_damage,
           :collision_damage,
           :terrain,
           :game_acceptance_timeout_ms,
           :move_timeout_ms
         ])
     }}
  end

  def game_over_message(game) do
    {:game_over, %{game: game}}
  end
end
