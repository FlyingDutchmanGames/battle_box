defmodule BattleBox.PlayerServer do
  use GenStateMachine, callback_mode: [:state_enter], restart: :temporary
  alias BattleBox.{Lobby, MatchMaker}

  def start_link(%{names: _} = config, %{connection: _, player_id: _} = data) do
    data = Map.put_new(data, :player_server_id, Ecto.UUID.generate())
    GenStateMachine.start_link(__MODULE__, Map.merge(config, data))
  end

  def init(%{names: names} = data) do
    connection_monitor = Process.monitor(data.connection)

    Registry.register(names.player_registry, data.player_server_id, %{
      player_id: data.player_id,
      status: :options,
      connection_status: :connected
    })

    data =
      Map.merge(data, %{
        connection_monitor: connection_monitor,
        connection_status: :connected
      })

    {:ok, :options, data}
  end

  def handle_event(:enter, _, state, data) when state in [:options],
    do: {:next_state, state, data}

  def handle_event({:call, from}, {:join_lobby, %{lobby_name: lobby_name}}, :options, data) do
    case Lobby.get_by_name(lobby_name) do
      %Lobby{} = lobby ->
        set_status(data.names.player_registry, data.player_server_id, {:match_making, lobby})
        :ok = MatchMaker.join_queue(data.names.game_engine, lobby.id, data.player_id)
        data = Map.put(data, :lobby, lobby)
        {:next_state, :match_making, data, [{:reply, from, :ok}]}

      nil ->
        {:keep_state, data, [{:reply, from, {:error, :lobby_not_found}}]}
    end

    :keep_state_and_data
  end

  def handle_event(:info, {:game_request, game_info}, :match_making, data) do
    game_monitor = Process.monitor(game_info.game_server)
    :ok = MatchMaker.dequeue_self(data.names.game_engine, data.lobby.id)
    data = Map.put(data, :game_monitor, game_monitor)
    {:next_state, :game_acceptance, data, []}
  end

  # {:game_request,
  #  %{
  #    game_server: self(),
  #    game_id: Game.id(game),
  #    player: player,
  #    settings: Game.settings(game)
  #  }}
  # {:moves_request,
  #  %{
  #    game_id: Game.id(game),
  #    game_state: Game.moves_request(game),
  #    turn: Game.turn(game),
  #    player: player
  #  }}

  # defp set_connection_status(registry, player_id, status) do
  #   Registry.update_value(registry, player_id, fn metadata ->
  #     Map.put(metadata, :connection_status, status)
  #   end)
  # end

  defp set_status(registry, player_server_id, status) do
    Registry.update_value(registry, player_server_id, fn metadata ->
      Map.put(metadata, :status, status)
    end)
  end
end
