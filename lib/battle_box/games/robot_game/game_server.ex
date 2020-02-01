defmodule BattleBox.Games.RobotGame.GameServer do
  alias BattleBox.Games.RobotGame.{Game, Game.Logic}
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]

  def accept_game(game_server, player) do
    GenStateMachine.call(game_server, {:accept_game, player})
  end

  def reject_game(game_server, player) do
    GenStateMachine.call(game_server, {:reject_game, player})
  end

  def submit_moves(game_server, player, moves) do
    GenStateMachine.call(game_server, {:moves, player, moves})
  end

  def start_link(%{player_1: _, player_2: _, game: _} = data) do
    GenStateMachine.start_link(__MODULE__, data)
  end

  def init(data) do
    {:ok, :game_acceptance, data, []}
  end

  def game_acceptance(:enter, _old_state, %{game: game} = data) do
    send(data.player_1, init_message(data.game, :player_1))
    send(data.player_2, init_message(data.game, :player_2))

    data = Map.put(data, :acceptances, [])

    {:keep_state, data}
  end

  def game_acceptance({:call, from}, {:accept_game, player}, data) do
    reply = {:reply, from, :ok}

    case data.acceptances do
      [] -> {:keep_state, put_in(data.acceptances, [player]), [reply]}
      [_first_acceptance] -> {:next_state, :moves, data, [reply]}
    end
  end

  def game_acceptance({:call, from}, {:reject_game, player}, data) do
    for p <- [:player_1, :player_2], p != player, do: send(p, {:game_cancelled, data.game.id})

    {:stop, :normal, [{:reply, from, {:game_cancelled, data.game.id}}]}
  end

  def moves(:enter, _old_state, data) do
    send(data.player_1, moves_request(data.game, :player_1))
    send(data.player_2, moves_request(data.game, :player_2))

    data = Map.put(data, :moves, [])

    {:keep_state, data}
  end

  def moves({:call, from}, {:moves, player, moves}, data) do
    reply = {:reply, from, :ok}

    case data.moves do
      [] ->
        {:keep_state, put_in(data.moves, [{player, moves}]), [reply]}

      [{other_player, other_moves}] when other_player != player ->
        moves = Enum.concat(moves, other_moves)
        data = update_in(data.game, &Logic.calculate_turn(&1, moves))

        if Game.over?(data.game),
          do: {:next_state, :finalize, data, [reply]},
          else: {:repeat_state, data, [reply]}
    end
  end

  def finalize(:enter, :moves, %{game: game} = data) do
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
end
