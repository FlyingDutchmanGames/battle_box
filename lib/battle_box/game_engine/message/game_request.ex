defmodule BattleBox.GameEngine.Message.GameRequest do
  alias BattleBox.{Arena, Bot, Game, GameBot, User}

  @derive Jason.Encoder
  @enforce_keys [
    :accept_time,
    :arena,
    :game_id,
    :game_server,
    :game_type,
    :player,
    :players,
    :settings
  ]

  defstruct @enforce_keys

  @spec new(pid(), integer(), %Game{}) :: %__MODULE__{}
  def new(
        game_server,
        player,
        %Game{
          id: game_id,
          game_bots: game_bots,
          arena: %Arena{} = arena,
          game_type: game_type
        } = game
      ) do
    players =
      for %GameBot{player: player} = game_bot <- game_bots, into: %{} do
        %Bot{name: name, user: %User{username: username, avatar_url: avatar_url}} = game_bot.bot
        {player, %{bot: %{name: name, user: %{username: username, avatar_url: avatar_url}}}}
      end

    %__MODULE__{
      accept_time: arena.game_acceptance_time_ms,
      arena: %{
        name: arena.name
      },
      game_id: game_id,
      game_server: game_server,
      game_type: game_type.name(),
      player: player,
      players: players,
      settings: Game.settings(game)
    }
  end
end
