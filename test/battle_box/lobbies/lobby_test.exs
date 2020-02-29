defmodule BattleBox.LobbyTest do
  use BattleBox.DataCase
  alias BattleBox.{Lobby, Repo}
  alias BattleBox.Games.RobotGame

  @user_id Ecto.UUID.generate()

  describe "game acceptance timeout" do
    test "the default game acceptance timeout is 2 seconds" do
      lobby = %Lobby{name: "Grant's Test", game_type: RobotGame, user_id: @user_id}
      assert lobby.game_acceptance_timeout_ms == 2000
    end

    test "you can set a custom game acceptance timeout" do
      {:ok, _} =
        Lobby.create(%{
          name: "Grant's Test",
          game_type: RobotGame,
          game_acceptance_timeout_ms: 42024,
          user_id: @user_id
        })

      retrieved_lobby = Lobby.get_by_name("Grant's Test")
      assert retrieved_lobby.game_acceptance_timeout_ms == 42024
    end
  end

  describe "validations" do
    test "Name must be greater than 3" do
      changeset = Lobby.changeset(%Lobby{user_id: @user_id}, %{name: "AA", game_type: RobotGame})
      refute changeset.valid?
    end

    test "Name may not be longer than 50" do
      name = :crypto.strong_rand_bytes(26) |> Base.encode16()
      assert String.length(name) > 50
      changeset = Lobby.changeset(%Lobby{user_id: @user_id}, %{name: name, game_type: RobotGame})
      refute changeset.valid?
    end
  end

  describe "queries" do
    test "with_user_id" do
      {:ok, _} = Lobby.create(%{name: "MINE", game_type: RobotGame, user_id: @user_id})

      {:ok, _} =
        Lobby.create(%{name: "NOT MINE", game_type: RobotGame, user_id: Ecto.UUID.generate()})

      assert [%{name: "MINE"}] = Lobby.with_user_id(@user_id) |> Repo.all()
    end
  end

  describe "persistence" do
    test "You can persist a lobby and get it back out" do
      {:ok, lobby} =
        Lobby.create(%{name: "Grant's Test", game_type: RobotGame, user_id: @user_id})

      retrieved_lobby = Lobby.get_by_name("Grant's Test")
      assert lobby.name == retrieved_lobby.name
      assert <<_::288>> = retrieved_lobby.id
    end
  end

  describe "settings" do
    test "lobbies are created with the default settings for their game mode" do
      {:ok, lobby} =
        Lobby.create(%{name: "Grant's Test", game_type: RobotGame, user_id: @user_id})

      %{id: <<_::288>>, attack_damage: _, terrain: _} = Lobby.get_settings_for_lobby(lobby)
    end
  end
end
