defmodule BattleBox.LobbyTest do
  use BattleBox.DataCase
  alias BattleBox.{Lobby, Repo}
  alias BattleBox.Games.RobotGame

  @user_id Ecto.UUID.generate()

  setup do
    {:ok, user} = create_user(id: @user_id)
    %{user: user}
  end

  describe "game acceptance timeout" do
    test "the default game timeouts are correct" do
      lobby = %Lobby{name: "Grant's Test", game_type: RobotGame, user_id: @user_id}
      assert lobby.game_acceptance_time_ms == 2000
      assert lobby.command_time_minimum_ms == 250
      assert lobby.command_time_maximum_ms == 1000
    end

    test "you can set a custom game acceptance timeout", %{user: user} do
      {:ok, _} =
        user
        |> Ecto.build_assoc(:lobbies)
        |> Lobby.changeset(%{
          name: "Grant's Test",
          game_type: RobotGame,
          game_acceptance_time_ms: 42024,
          command_time_minimum_ms: 1234,
          command_time_maximum_ms: 5678
        })
        |> Repo.insert()

      lobby = Repo.get_by(Lobby, name: "Grant's Test")
      assert lobby.game_acceptance_time_ms == 42024
      assert lobby.command_time_minimum_ms == 1234
      assert lobby.command_time_maximum_ms == 5678
    end
  end

  describe "validations" do
    test "Name must not be blank" do
      changeset = Lobby.changeset(%Lobby{}, %{name: ""})
      assert changeset.errors[:name] == {"can't be blank", [validation: :required]}
    end

    test "Name may not be longer than 50" do
      name = :crypto.strong_rand_bytes(26) |> Base.encode16()
      assert String.length(name) > 50

      changeset = Lobby.changeset(%Lobby{}, %{name: name})

      assert changeset.errors[:name] ==
               {"should be at most %{count} character(s)",
                [{:count, 50}, {:validation, :length}, {:kind, :max}, {:type, :string}]}
    end
  end

  describe "persistence" do
    test "You can persist a lobby and get it back out", %{user: user} do
      assert {:ok, lobby} =
               user
               |> Ecto.build_assoc(:lobbies)
               |> Lobby.changeset(%{name: "Grant's Test", game_type: "robot_game"})
               |> Repo.insert()
    end
  end
end
