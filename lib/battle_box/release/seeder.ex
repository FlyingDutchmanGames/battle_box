defmodule BattleBox.Release.Seeder do
  require Logger
  import BattleBox.InstalledGames, only: [installed_games: 0]
  alias BattleBox.{Arena, Bot, User, Repo}

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

      Logger.info("Creating/Updating System Arenas for #{game.title}")

      for %{name: name} = params <- game.default_arenas() do
        params =
          params
          |> Map.put(:game_type, game)
          |> Map.put(game.settings_module.name, params[:settings])

        {:ok, _arena} =
          case Repo.get_by(Arena, name: name) do
            nil ->
              Ecto.build_assoc(system_user, :arenas)

            %Arena{} = arena ->
              Arena.preload_game_settings(arena)
          end
          |> Arena.changeset(params)
          |> Repo.insert_or_update()
      end
    end

    :ok
  end
end
