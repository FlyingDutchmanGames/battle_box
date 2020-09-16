defmodule BattleBox.Release.SeederTest do
  use BattleBox.DataCase, async: true
  alias BattleBox.{Arena, Bot, User, Repo}
  import BattleBox.InstalledGames, only: [installed_games: 0]

  alias BattleBox.Release.Seeder

  test "you can run it once, and have it create data" do
    assert [] == Repo.all(User)
    assert [] == Repo.all(Bot)
    assert [] == Repo.all(Arena)

    :ok = Seeder.seed()

    users = for %{username: username} <- Repo.all(User), do: username
    assert "Botskrieg" in users
    assert "Anonymous" in users

    bots = for %{name: name} <- Repo.all(Bot), do: name
    arenas = for %{name: name} <- Repo.all(Arena), do: name

    for game <- installed_games() do
      for ai <- game.ais do
        assert ai.name in bots
      end

      for %{name: name} <- game.default_arenas do
        assert name in arenas
      end
    end
  end

  test "you can run it twice without errors" do
    assert :ok = Seeder.seed()
    assert :ok = Seeder.seed()
  end
end
