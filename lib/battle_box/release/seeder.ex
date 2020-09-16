defmodule BattleBox.Release.Seeder do
  require Logger
  import BattleBox.InstalledGames, only: [installed_games: 0]
  alias BattleBox.{User, Bot, Arena}

  @moduledoc """
  Used to set up all the default user/bots/arenas that
  are needed for some freatures
  """
  def child_spec(skip_seed?: skip_seed?) do
    %{
      id: __MODULE__,
      restart: :transient,
      start:
        {Task, :start_link,
         [
           fn ->
             unless skip_seed?, do: seed()
           end
         ]}
    }
  end

  def seed do
    Logger.info("Seeding the database")

    Logger.info("Creating/Updating System Users")
    system_user = User.system_user()
    %User{} = User.anon_human_user()

    for game <- installed_games() do
      Logger.info("Creating/Updating System Bots for #{game.title}")

      for ai <- game.ais,
          do: {:ok, %Bot{}} = Bot.system_bot(ai.name)
    end
  end
end
