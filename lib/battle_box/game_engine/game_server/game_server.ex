defmodule BattleBox.GameEngine.GameServer do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter], restart: :temporary
  alias BattleBox.{Repo, Game, GameEngine}

  def get_game(game_server) do
    GenStateMachine.call(game_server, :get_game)
  end

  def accept_game(game_server, player) when is_integer(player) do
    GenStateMachine.cast(game_server, {:accept_game, player})
  end

  def reject_game(game_server, player) when is_integer(player) do
    GenStateMachine.cast(game_server, {:reject_game, player})
  end

  def forfeit_game(game_server, player) when is_integer(player) do
    GenStateMachine.cast(game_server, {:forfeit_game, player})
  end

  def submit_commands(game_server, player, commands) when is_integer(player) do
    GenStateMachine.cast(game_server, {:commands, player, commands})
  end

  def start_link(config, %{players: _, game: game} = data) do
    GenStateMachine.start_link(__MODULE__, Map.merge(config, data),
      name: {:via, Registry, {config.names.game_registry, game.id, initial_metadata(game)}}
    )
  end

  def init(data) do
    :ok = GameEngine.broadcast_game_start(data.names.game_engine, data.game)
    {:ok, :game_acceptance, data, {:next_event, :internal, :setup}}
  end

  def handle_event({:call, from}, :get_game, _state, data) do
    {:keep_state_and_data, {:reply, from, {:ok, data.game}}}
  end

  def handle_event(:internal, :setup, :game_acceptance, data) do
    data = update_in(data.game, &Repo.preload(&1, :arena))

    for {player, pid} <- data.players do
      Process.monitor(pid)
      send(pid, init_message(data.game, player))
    end

    {:keep_state, Map.put(data, :acceptances, [])}
  end

  def handle_event(:cast, {:accept_game, player}, :game_acceptance, data) do
    case data.acceptances do
      [] ->
        {:keep_state, put_in(data.acceptances, [player])}

      [_first_acceptance] ->
        {:next_state, :commands, data, {:next_event, :internal, :collect_commands}}
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

  def handle_event(:internal, :collect_commands, :commands, data) do
    requests = Game.commands_requests(data.game)

    for {player, request} <- requests do
      send(data.players[player], commands_request(data.game, player, request))
    end

    commands = Map.new(requests, fn {player, _} -> {player, nil} end)

    {:keep_state, Map.put(data, :commands, commands)}
  end

  def handle_event(:cast, {:commands, player, commands}, :commands, data) do
    commands = Map.put(data.commands, player, commands)

    if Enum.all?(Map.values(commands)) do
      %{game: game, debug: debug, info: info} = Game.calculate_turn(data.game, commands)
      data = put_in(data.game, game)

      for {player, msg} <- debug do
        send(data.players[player], debug_info(data.game, msg))
      end

      for {player, msg} <- info do
        send(data.players[player], game_info(data.game, msg))
      end

      if Game.over?(data.game),
        do: {:keep_state, data, {:next_event, :internal, :finalize}},
        else: {:repeat_state, data, {:next_event, :internal, :collect_commands}}
    else
      {:keep_state, put_in(data.commands, commands)}
    end
  end

  def handle_event(:cast, {:forfeit_game, player}, :commands, data) do
    {:keep_state, update_in(data.game, &Game.disqualify(&1, player)),
     {:next_event, :internal, :finalize}}
  end

  def handle_event(:info, {:DOWN, _, :process, pid, _}, :commands, data) do
    {player, _} = Enum.find(data.players, fn {_player, player_pid} -> player_pid == pid end)

    {:keep_state, update_in(data.game, &Game.disqualify(&1, player)),
     {:next_event, :internal, :finalize}}
  end

  def handle_event(:internal, :finalize, _state, %{game: game} = data) do
    {:ok, game} = Repo.insert(game)

    for {_player, pid} <- data.players do
      send(pid, game_over_message(game))
    end

    {:stop, :normal}
  end

  def handle_event(:enter, _, new_state, %{names: names, game: game}) do
    metadata = %{status: new_state, game: Game.metadata_only(game)}
    {_, _} = Registry.update_value(names.game_registry, game.id, &Map.merge(&1, metadata))
    :ok = GameEngine.broadcast_game_update(names.game_engine, game)
    :keep_state_and_data
  end

  defp commands_request(game, player, request) do
    {:commands_request,
     %{
       game_id: game.id,
       game_state: request,
       minimum_time: game.arena.command_time_minimum_ms,
       maximum_time: game.arena.command_time_maximum_ms,
       player: player
     }}
  end

  defp game_info(game, game_info) do
    {:game_info,
     %{
       game_id: game.id,
       game_info: game_info
     }}
  end

  defp debug_info(game, debug) do
    {:debug_info,
     %{
       game_id: game.id,
       debug_info: debug
     }}
  end

  defp init_message(game, player) do
    {:game_request,
     %{
       game_server: self(),
       game_id: game.id,
       game_type: game.game_type.name,
       player: player,
       accept_time: game.arena.game_acceptance_time_ms,
       settings: Game.settings(game)
     }}
  end

  def game_over_message(game) do
    {:game_over, %{game_id: game.id, score: Game.score(game)}}
  end

  defp initial_metadata(game), do: %{started_at: DateTime.utc_now(), game: game}
end
