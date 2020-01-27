defmodule BattleBox.Games.RobotGame.GameServer do
  alias BattleBox.Games.RobotGame.{Game, Game.Logic}
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]

  def accept_game(game_server, player) do
    GenStateMachine.call(game_server, {:accept_game, player})
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

    data = Map.merge(data, %{first_acceptance: nil})

    {:keep_state, data,
     [{:state_timeout, game.game_acceptance_timeout_ms, :game_acceptance_timeout}]}
  end

  def game_acceptance({:call, from}, {:accept_game, player}, %{first_acceptance: nil} = data) do
    {:keep_state, %{data | first_acceptance: player}, [{:reply, from, :ok}]}
  end

  def game_acceptance({:call, from}, {:accept_game, player}, data) do
    {:next_state, :moves, data, [{:reply, from, :ok}]}
  end

  def game_acceptance(:state_timeout, :game_acceptance_timeout, data) do
    cancellation = {:game_cancelled, data.game.id}
    send(data.player_1, cancellation)
    send(data.player_2, cancellation)

    {:stop, :normal}
  end

  def moves(:enter, _old_state, data) do
    send(data.player_1, moves_request(data.game, :player_1))
    send(data.player_2, moves_request(data.game, :player_2))

    data = Map.put(data, :first_moves, nil)

    {:keep_state, data, [{:state_timeout, data.game.move_timeout_ms, :move_timeout}]}
  end

  def moves({:call, from}, {:moves, player, moves}, %{first_moves: nil} = data) do
    {:keep_state, %{data | first_moves: {player, moves}}, [{:reply, from, :ok}]}
  end

  def moves({:call, from}, {:moves, _, moves_1}, %{first_moves: {_, moves_2}} = data) do
    moves = Enum.concat(moves_1, moves_2)
    data = update_in(data.game, &Logic.calculate_turn(&1, moves))

    if Game.over?(data.game),
      do: {:next_state, :finalize, data, [{:reply, from, :ok}]},
      else: {:repeat_state, data, [{:reply, from, :ok}]}
  end

  def moves(:state_timeout, :move_timeout, data) do
    IO.inspect("MOVES STATE TIMEOUT")

    move_timeout_player =
      %{player_1: :player_2, player_2: :player_1, nil: :both}[data.first_moves]

    data = Map.put(data, :move_timeout_player, move_timeout_player)

    {:next_state, :finalize, data, []}
  end

  def finalize(:enter, :moves, %{game: game} = data) do
    {:stop, :normal}
  end

  defp moves_request(game, player) do
    {:moves_request,
     %{
       robots: Game.robots(game),
       turn: game.turn,
       player: player
     }}
  end

  defp init_message(game, player) do
    {:game_request,
     %{
       game_server: self(),
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
