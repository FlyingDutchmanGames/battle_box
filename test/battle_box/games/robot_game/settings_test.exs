defmodule BattleBox.Games.RobotGame.SettingsTest do
  use BattleBox.DataCase
  alias BattleBox.Repo
  alias BattleBox.Games.{RobotGame.Settings, RobotGame.Settings.Terrain}

  describe "persistence" do
    test "you can save it and pull it back out" do
      {:ok, %{id: id}} =
        %Settings{arena_id: Ecto.UUID.generate()}
        |> Repo.insert()

      %Settings{id: ^id} = Repo.get(Settings, id)
    end
  end

  describe "changeset" do
    test "it requires the required fields" do
      changeset =
        %Settings{}
        |> Settings.changeset(%{
          attack_damage_max: nil,
          attack_damage_min: nil,
          collision_damage_max: nil,
          collision_damage_min: nil,
          max_turns: nil,
          robot_hp: nil,
          spawn_every: nil,
          spawn_per_player: nil,
          suicide_damage_max: nil,
          suicide_damage_min: nil,
          terrain_base64: nil
        })

      assert Enum.sort(Keyword.keys(changeset.errors)) == [
               :attack_damage_max,
               :attack_damage_min,
               :collision_damage_max,
               :collision_damage_min,
               :max_turns,
               :robot_hp,
               :spawn_every,
               :spawn_per_player,
               :suicide_damage_max,
               :suicide_damage_min,
               :terrain_base64
             ]
    end

    test "it forces all the numbers within the proper range" do
      [
        {:spawn_every, 0,
         {"must be greater than or equal to %{number}",
          [validation: :number, kind: :greater_than_or_equal_to, number: 1]}},
        {:spawn_per_player, 0,
         {"must be greater than or equal to %{number}",
          [validation: :number, kind: :greater_than_or_equal_to, number: 1]}},
        {:spawn_per_player, 21,
         {"must be less than or equal to %{number}",
          [validation: :number, kind: :less_than_or_equal_to, number: 20]}},
        {:robot_hp, 0,
         {"must be greater than or equal to %{number}",
          [validation: :number, kind: :greater_than_or_equal_to, number: 1]}},
        {:robot_hp, 101,
         {"must be less than or equal to %{number}",
          [validation: :number, kind: :less_than_or_equal_to, number: 100]}},
        {:max_turns, 0,
         {"must be greater than or equal to %{number}",
          [validation: :number, kind: :greater_than_or_equal_to, number: 1]}},
        {:max_turns, 501,
         {"must be less than or equal to %{number}",
          [validation: :number, kind: :less_than_or_equal_to, number: 500]}}
      ]
      |> Enum.each(fn {field, amount, error_msg} ->
        changeset =
          %Settings{}
          |> Settings.changeset(%{field => amount})

        assert changeset.errors[field] == error_msg
      end)
    end

    test "it validates the relationships between mins/maxs" do
      changeset =
        Settings.changeset(%Settings{}, %{
          attack_damage_max: 1,
          attack_damage_min: 2,
          collision_damage_max: 1,
          collision_damage_min: 2,
          suicide_damage_max: 1,
          suicide_damage_min: 2
        })

      assert changeset.errors == [
               collision_damage_min:
                 {"collision_damage_min must be less than or equal to collision_damage_max", []},
               suicide_damage_min:
                 {"suicide_damage_min must be less than or equal to suicide_damage_max", []},
               attack_damage_min:
                 {"attack_damage_min must be less than or equal to attack_damage_max", []}
             ]
    end

    test "it validate the terrain" do
      [
        {<<1>>, {"Illegal Size Header", []}},
        {<<1, 1>>, {"Terrain data byte size must equal rows * cols", []}},
        {<<41, 1>>, {"Rows and cols must be between 1 and 40", []}},
        {<<1, 41>>, {"Rows and cols must be between 1 and 40", []}},
        {Terrain.default(), nil}
      ]
      |> Enum.each(fn {terrain, error_msg} ->
        changeset =
          %Settings{}
          |> Settings.changeset(%{terrain_base64: Base.encode64(terrain)})

        assert changeset.errors[:terrain_base64] == error_msg
      end)
    end
  end
end
