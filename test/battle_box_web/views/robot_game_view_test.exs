defmodule BattleBoxWeb.RobotGameViewTest do
  use BattleBoxWeb.ConnCase, async: true
  alias BattleBoxWeb.RobotGameView
  import Phoenix.View

  describe "terrain_number/1" do
    test "the terrain numbering of a starting column is displayed" do
      assert 10 == RobotGameView.terrain_number({0, 10})
    end

    test "the terrain numbering of a starting row is displayed" do
      assert 10 == RobotGameView.terrain_number({10, 0})
    end

    test "0 is displayed at the origin" do
      assert 0 == RobotGameView.terrain_number({0, 0})
    end
  end

  describe "render terrain.html" do
    test "you can render terrain" do
      html = render_to_string(RobotGameView, "terrain.html", terrain: :normal, location: {0, 0})

      [div] = Floki.find(html, "div.terrain.normal")
      assert ["grid-row: 1; grid-column: 1;"] == Floki.attribute(div, "style")
      [number] = Floki.find(div, ".number")
      assert Floki.text(number) == "0"
    end

    test "Terrain that is not on an edge doesn't have a number" do
      html = render_to_string(RobotGameView, "terrain.html", terrain: :normal, location: {1, 1})
      [number] = Floki.find(html, "div.terrain .number")
      assert Floki.text(number) == ""
    end

    test "you can render all the types of terrains" do
      [:normal, :spawn, :obstacle, :inaccesible]
      |> Enum.map(fn terrain ->
        html = render_to_string(RobotGameView, "terrain.html", terrain: terrain, location: {1, 1})
        assert [div] = Floki.find(html, ".terrain.#{terrain}")
      end)
    end
  end
end
