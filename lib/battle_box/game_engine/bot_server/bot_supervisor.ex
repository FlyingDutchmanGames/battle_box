defmodule BattleBox.GameEngine.BotServer.BotSupervisor do
  use DynamicSupervisor
  alias BattleBox.{Bot, Lobby, GameEngine.BotServer}

  def start_link(%{names: names} = opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: names.bot_supervisor)
  end

  def init(opts) do
    init_arg = Map.take(opts, [:names])
    DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: [init_arg])
  end

  def start_bot(
        bot_supervisor,
        %{connection: connection, lobby_name: lobby_name, token: token}
      ) do
    with {:lobby, %Lobby{} = lobby} <- {:lobby, Lobby.get_by_name(lobby_name)},
         {:bot, %Bot{} = bot} <- {:bot, Bot.get_by_token(token)} do
      start_bot(bot_supervisor, %{connection: connection, bot: bot, lobby: lobby})
    else
      {:bot, nil} ->
        {:error, :invalid_token}

      {:lobby, nil} ->
        {:error, :lobby_not_found}
    end
  end

  def start_bot(
        bot_supervisor,
        %{lobby: %Lobby{} = lobby, bot: %Bot{} = bot, connection: connection}
      ) do
    {:ok, bot_server} =
      DynamicSupervisor.start_child(
        bot_supervisor,
        {BotServer, %{bot: bot, lobby: lobby, connnection: connection}}
      )

    {:ok, bot_server, %{user_id: bot.user_id}}
  end

  def bot_servers_with_connection_id(bot_registry, connection_id) do
    Registry.select(bot_registry, matches_connection_id(connection_id))
    |> Enum.map(fn {bot_server_id, pid, attrs} ->
      Map.merge(attrs, %{bot_server_id: bot_server_id, pid: pid})
    end)
  end

  defp matches_connection_id(connection_id) do
    # :ets.fun2ms(fn {bot_server_id, pid, attrs} when :erlang.map_get(:connection_id, attrs) == connection_id ->
    #  {bot_server_id, pid, attrs}
    # end)

    [
      {{:"$1", :"$2", :"$3"}, [{:==, {:map_get, :connection_id, :"$3"}, {:const, connection_id}}],
       [{{:"$1", :"$2", :"$3"}}]}
    ]
  end
end
