defmodule BattleBox.LobbyTest do
  use BattleBox.DataCase
  alias BattleBox.{Lobby, Repo}
  alias BattleBox.Games.RobotGame.Game

  describe "game acceptance timeout" do
    test "the default game acceptance timeout is 2 seconds" do
      lobby = %Lobby{name: "Grant's Test", game_type: Game}
      assert lobby.game_acceptance_timeout_ms == 2000
    end

    test "you can set a custom game acceptance timeout" do
      lobby = %Lobby{name: "Grant's Test", game_type: Game, game_acceptance_timeout_ms: 42024}
      {:ok, _} = Repo.insert(Lobby.changeset(lobby))
      retrieved_lobby = Lobby.get_by_name("Grant's Test")
      assert retrieved_lobby.game_acceptance_timeout_ms == 42024
    end
  end

  describe "validations" do
    test "Name must be greater than 3" do
      changeset = Lobby.changeset(%Lobby{}, %{name: "AA", game_type: Game})
      refute changeset.valid?
    end

    test "Name may not be longer than 50" do
      name = :crypto.strong_rand_bytes(26) |> Base.encode16()
      assert String.length(name) > 50
      changeset = Lobby.changeset(%Lobby{}, %{name: name, game_type: Game})
      refute changeset.valid?
    end
  end

  describe "persistence" do
    test "You can persist a lobby and get it back out" do
      lobby = %Lobby{name: "Grant's Test", game_type: Game}
      {:ok, _} = Repo.insert(Lobby.changeset(lobby))
      retrieved_lobby = Lobby.get_by_name("Grant's Test")
      assert lobby.name == retrieved_lobby.name
      assert <<_::288>> = retrieved_lobby.id
    end
  end
end
