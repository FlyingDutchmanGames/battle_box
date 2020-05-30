defmodule BattleBox.LobbyTest do
  use BattleBox.DataCase
  alias BattleBox.{Lobby, Repo}
  import BattleBox.InstalledGames

  @user_id Ecto.UUID.generate()

  setup do
    {:ok, user} = create_user(id: @user_id)
    %{user: user}
  end

  describe "default timeouts" do
    test "the default game timeouts are correct" do
      lobby = %Lobby{name: "Grant's Test", user_id: @user_id}
      assert lobby.game_acceptance_time_ms == 2000
      assert lobby.command_time_minimum_ms == 250
      assert lobby.command_time_maximum_ms == 1000
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

    test "game_type must be an installed game" do
      for game <- installed_games() do
        changeset = Lobby.changeset(%Lobby{}, %{game_type: "#{game.name}"})
        assert changeset.errors[:game_type] == nil
      end

      changeset = Lobby.changeset(%Lobby{}, %{game_type: "NOT A REAL GAME"})

      assert changeset.errors[:game_type] ==
               {"is invalid", [type: BattleBox.Lobby.GameType, validation: :cast]}
    end

    test "game acceptance time must be in range" do
      changeset = Lobby.changeset(%Lobby{}, %{game_acceptance_time_ms: 999})

      assert changeset.errors[:game_acceptance_time_ms] ==
               {"must be greater than or equal to %{number}",
                [{:validation, :number}, {:kind, :greater_than_or_equal_to}, {:number, 1000}]}

      changeset = Lobby.changeset(%Lobby{}, %{game_acceptance_time_ms: 10001})

      assert changeset.errors[:game_acceptance_time_ms] ==
               {"must be less than %{number}",
                [validation: :number, kind: :less_than, number: 10000]}
    end

    test "command time minimum must be in range" do
      changeset = Lobby.changeset(%Lobby{}, %{command_time_minimum_ms: 249})

      assert changeset.errors[:command_time_minimum_ms] ==
               {"must be greater than or equal to %{number}",
                [validation: :number, kind: :greater_than_or_equal_to, number: 250]}

      changeset =
        Lobby.changeset(%Lobby{}, %{command_time_minimum_ms: 1001, command_time_maximum_ms: 999})

      assert changeset.errors[:command_time_minimum_ms] ==
               {"Minimum command time must be less than maximum command time", []}

      changeset =
        Lobby.changeset(%Lobby{}, %{command_time_minimum_ms: 1001, command_time_maximum_ms: 1002})

      assert changeset.errors[:command_time_minimum_ms] ==
               {"must be less than %{number}",
                [validation: :number, kind: :less_than, number: 1000]}
    end

    test "command time maximum must be in range" do
      changeset = Lobby.changeset(%Lobby{}, %{command_time_maximum_ms: 249})

      assert changeset.errors[:command_time_maximum_ms] ==
               {"must be greater than or equal to %{number}",
                [validation: :number, kind: :greater_than_or_equal_to, number: 250]}

      changeset = Lobby.changeset(%Lobby{}, %{command_time_maximum_ms: 10001})

      assert changeset.errors[:command_time_maximum_ms] ==
               {"must be less than %{number}",
                [validation: :number, kind: :less_than, number: 10000]}
    end
  end

  test "lobby name is case insenstive", %{user: user} do
    assert {:ok, lobby} =
             user
             |> Ecto.build_assoc(:lobbies)
             |> Lobby.changeset(%{name: "ABC", game_type: "robot_game", robot_game_settings: %{}})
             |> Repo.insert()

    assert %Lobby{name: "ABC"} = Repo.get_by(Lobby, name: "AbC")
    assert %Lobby{name: "ABC"} = Repo.get_by(Lobby, name: "aBc")
    assert %Lobby{name: "ABC"} = Repo.get_by(Lobby, name: "abc")
  end

  describe "persistence" do
    test "You can persist a lobby and get it back out", %{user: user} do
      assert {:ok, lobby} =
               user
               |> Ecto.build_assoc(:lobbies)
               |> Lobby.changeset(%{
                 name: "Grant's Test",
                 game_type: "robot_game",
                 robot_game_settings: %{}
               })
               |> Repo.insert()
    end
  end
end
