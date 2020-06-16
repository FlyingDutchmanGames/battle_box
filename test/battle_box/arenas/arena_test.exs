defmodule BattleBox.ArenaTest do
  use BattleBox.DataCase
  alias BattleBox.{Arena, Repo}
  import BattleBox.InstalledGames

  @user_id Ecto.UUID.generate()

  setup do
    {:ok, user} = create_user(id: @user_id)
    %{user: user}
  end

  describe "default timeouts" do
    test "the default game timeouts are correct" do
      arena = %Arena{name: "grant-test", user_id: @user_id}
      assert arena.game_acceptance_time_ms == 2000
      assert arena.command_time_minimum_ms == 250
      assert arena.command_time_maximum_ms == 1000
    end
  end

  describe "validations" do
    test "Name must not be blank" do
      changeset = Arena.changeset(%Arena{}, %{name: ""})
      assert changeset.errors[:name] == {"can't be blank", [validation: :required]}
    end

    test "Name may not be longer than 39" do
      name = :binary.copy("a", 40)
      changeset = Arena.changeset(%Arena{}, %{name: name})

      assert changeset.errors[:name] ==
               {"should be at most %{count} character(s)",
                [{:count, 39}, {:validation, :length}, {:kind, :max}, {:type, :string}]}
    end

    test "game_type must be an installed game" do
      for game <- installed_games() do
        changeset = Arena.changeset(%Arena{}, %{game_type: "#{game.name}"})
        assert changeset.errors[:game_type] == nil
      end

      changeset = Arena.changeset(%Arena{}, %{game_type: "NOT A REAL GAME"})

      assert changeset.errors[:game_type] ==
               {"is invalid", [type: BattleBox.Arena.GameType, validation: :cast]}
    end

    test "game acceptance time must be in range" do
      changeset = Arena.changeset(%Arena{}, %{game_acceptance_time_ms: 999})

      assert changeset.errors[:game_acceptance_time_ms] ==
               {"must be greater than or equal to %{number}",
                [{:validation, :number}, {:kind, :greater_than_or_equal_to}, {:number, 1000}]}

      changeset = Arena.changeset(%Arena{}, %{game_acceptance_time_ms: 10001})

      assert changeset.errors[:game_acceptance_time_ms] ==
               {"must be less than %{number}",
                [validation: :number, kind: :less_than, number: 10000]}
    end

    test "command time minimum must be in range" do
      changeset = Arena.changeset(%Arena{}, %{command_time_minimum_ms: 249})

      assert changeset.errors[:command_time_minimum_ms] ==
               {"must be greater than or equal to %{number}",
                [validation: :number, kind: :greater_than_or_equal_to, number: 250]}

      changeset =
        Arena.changeset(%Arena{}, %{command_time_minimum_ms: 1001, command_time_maximum_ms: 999})

      assert changeset.errors[:command_time_minimum_ms] ==
               {"Minimum command time must be less than maximum command time", []}

      changeset =
        Arena.changeset(%Arena{}, %{command_time_minimum_ms: 1001, command_time_maximum_ms: 1002})

      assert changeset.errors[:command_time_minimum_ms] ==
               {"must be less than %{number}",
                [validation: :number, kind: :less_than, number: 1000]}
    end

    test "command time maximum must be in range" do
      changeset = Arena.changeset(%Arena{}, %{command_time_maximum_ms: 249})

      assert changeset.errors[:command_time_maximum_ms] ==
               {"must be greater than or equal to %{number}",
                [validation: :number, kind: :greater_than_or_equal_to, number: 250]}

      changeset = Arena.changeset(%Arena{}, %{command_time_maximum_ms: 10001})

      assert changeset.errors[:command_time_maximum_ms] ==
               {"must be less than %{number}",
                [validation: :number, kind: :less_than, number: 10000]}
    end
  end

  test "arena name is case insenstive", %{user: user} do
    assert {:ok, _arena} =
             user
             |> Ecto.build_assoc(:arenas)
             |> Arena.changeset(%{name: "ABC", game_type: "robot_game", robot_game_settings: %{}})
             |> Repo.insert()

    assert %Arena{name: "ABC"} = Repo.get_by(Arena, name: "AbC")
    assert %Arena{name: "ABC"} = Repo.get_by(Arena, name: "aBc")
    assert %Arena{name: "ABC"} = Repo.get_by(Arena, name: "abc")
  end

  describe "persistence" do
    test "You can persist a arena and get it back out", %{user: user} do
      assert {:ok, arena} =
               user
               |> Ecto.build_assoc(:arenas)
               |> Arena.changeset(%{
                 name: "test-name",
                 game_type: "robot_game",
                 robot_game_settings: %{}
               })
               |> Repo.insert()

      assert %Arena{} = Repo.get(Arena, arena.id)
    end
  end
end
