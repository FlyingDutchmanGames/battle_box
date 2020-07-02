defmodule BattleBox.GameEngine.AiServer do
  alias BattleBox.GameEngine.GameServer
  use GenServer, restart: :temporary

  def start_link(%{names: _} = config, data) do
    data = Map.put_new(data, :ai_id, Ecto.UUID.generate())

    GenServer.start_link(__MODULE__, Map.merge(config, data),
      name: {:via, Registry, {config.names.ai_registry, data.ai_id, %{}}}
    )
  end

  def init(data) do
    {:ok, data}
  end

  def handle_info(
        {:game_request, %{player: player, game_server: game_server} = game_request},
        state
      ) do
    :ok = GameServer.accept_game(game_server, player)
    ai_state = state.logic.initialize.(game_request.settings)

    {:noreply,
     Map.merge(state, %{
       game_request: game_request,
       ai_state: ai_state
     })}
  end

  def handle_info({:commands_request, commands_request}, state) do
    %{game_state: game_state} = commands_request

    {commands, ai_state} =
      state.logic.commands.(%{
        ai_state: state.ai_state,
        game_state: game_state,
        settings: state.settings,
        player: state.game_request.player
      })

    :ok =
      GameServer.submit_commands(
        state.game_request.game_server,
        state.game_request.player,
        commands
      )

    {:noreply, Map.put(state, :ai_state, ai_state)}
  end
end
