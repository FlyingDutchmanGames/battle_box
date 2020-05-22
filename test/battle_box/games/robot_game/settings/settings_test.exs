defmodule BattleBox.Games.RobotGame.SettingsTest do
  use BattleBox.DataCase
  alias BattleBox.{Repo, Games.RobotGame.Settings}

  describe "persistence" do
    test "you can save it and pull it back out" do
      {:ok, %{id: id}} =
        %Settings{lobby_id: Ecto.UUID.generate()}
        |> Repo.insert()

      %Settings{id: ^id} = Repo.get(Settings, id)
    end
  end
end
