defmodule BattleBox.GameEngine.BotServer.BotSupervisor do
  use DynamicSupervisor
  alias BattleBox.{Bot, Lobby, GameEngine, GameEngine.BotServer}

  def start_link(%{names: names} = opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: names.bot_supervisor)
  end

  def init(opts) do
    init_arg = Map.take(opts, [:names])
    DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: [init_arg])
  end

  def start_bot(
        game_engine,
        %{connection: connection, lobby_name: lobby_name, token: token}
      ) do
    with {:lobby, %Lobby{} = lobby} <- {:lobby, Lobby.get_by_name(lobby_name)},
         {:bot, %Bot{} = bot} <- {:bot, Bot.get_by_token(token)} do
      start_bot(game_engine, %{connection: connection, bot: bot, lobby: lobby})
    else
      {:bot, nil} ->
        {:error, :invalid_token}

      {:lobby, nil} ->
        {:error, :lobby_not_found}
    end
  end

  def start_bot(game_engine, %{lobby: %Lobby{}, bot: %Bot{} = bot, connection: _} = opts) do
    bot_supervisor = GameEngine.names(game_engine).bot_supervisor
    opts = Map.put_new(opts, :bot_server_id, Ecto.UUID.generate())
    {:ok, bot_server} = DynamicSupervisor.start_child(bot_supervisor, {BotServer, opts})
    GameEngine.broadcast_bot_server_started(game_engine, opts)
    {:ok, bot_server, %{user_id: bot.user_id}}
  end

  def get_bot_servers_with_user_id(bot_registry, user_id) do
    get_from_registry(bot_registry, matches_user_id(user_id))
  end

  defp get_from_registry(registry, match_spec) do
    Registry.select(registry, match_spec)
    |> Enum.map(fn {bot_server_id, pid, attrs} ->
      Map.merge(attrs, %{bot_server_id: bot_server_id, pid: pid})
    end)
  end

  # As of this writing (Elixir 1.10.1) `Registry.select/1` does not accept match specs that use `:'$_'`
  # these match specs could be much more concisely written if `:'$_'` was available

  defp matches_user_id(user_id) do
    # :ets.fun2ms(fn {bot_server_id, pid, attrs} when :erlang.map_get(:user_id, :erlang.map_get(:bot, attrs)) == 2 ->
    #   {bot_server_id, pid, attrs}
    # end)

    [
      {{:"$1", :"$2", :"$3"}, [{:==, {:map_get, :user_id, {:map_get, :bot, :"$3"}}, user_id}],
       [{{:"$1", :"$2", :"$3"}}]}
    ]
  end
end
