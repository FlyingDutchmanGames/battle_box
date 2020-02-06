defmodule BattleBox.LobbyTest do
  use BattleBox.DataCase
  alias BattleBox.{Lobby, Repo}
  alias BattleBox.Games.RobotGame.Game

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
