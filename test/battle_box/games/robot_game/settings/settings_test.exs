defmodule BattleBox.Games.RobotGame.SettingsTest do
  use BattleBox.DataCase
  alias BattleBox.{Repo, Games.RobotGame.Settings}

  describe "persistence" do
    test "you can save it and pull it back out" do
      {:ok, %{id: id}} =
        Settings.new()
        |> Repo.insert()

      %Settings{id: ^id} = Settings.get_by_id(id)
    end
  end
end
