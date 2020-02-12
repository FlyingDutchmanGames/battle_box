defmodule BattleBoxWeb.RobotGameViewTest do
  use BattleBoxWeb.ConnCase, async: true
  alias BattleBoxWeb.RobotGameView
  alias BattleBox.Games.RobotGame.Game
  import Phoenix.View
  import BattleBox.Games.RobotGameTest.Helpers

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
      {:ok, document} =
        render_to_string(RobotGameView, "terrain.html", terrain: :normal, location: {0, 0})
        |> Floki.parse_document()

      [div] = Floki.find(document, "div.terrain.normal")
      assert ["grid-row: 1; grid-column: 1;"] == Floki.attribute(div, "style")
      [number] = Floki.find(div, ".number")
      assert Floki.text(number) == "0"
    end

    test "Terrain that is not on an edge doesn't have a number" do
      {:ok, document} =
        render_to_string(RobotGameView, "terrain.html", terrain: :normal, location: {1, 1})
        |> Floki.parse_document()

      [number] = Floki.find(document, "div.terrain .number")
      assert Floki.text(number) == ""
    end

    test "you can render all the types of terrains" do
      [:normal, :spawn, :obstacle, :inaccesible]
      |> Enum.map(fn terrain ->
        {:ok, document} =
          render_to_string(RobotGameView, "terrain.html", terrain: terrain, location: {1, 1})
          |> Floki.parse_document()

        assert [_div] = Floki.find(document, ".terrain.#{terrain}")
      end)
    end
  end

  describe "render robot.html" do
    test "you can render a robot" do
      robot = %{id: "test", player_id: "player_1", location: {1, 1}, hp: 50}

      {:ok, document} =
        render_to_string(RobotGameView, "robot.html", robot: robot, move: nil, selected: false)
        |> Floki.parse_document()

      assert [robot_div] = Floki.find(document, ".robot.player_1")
      assert "grid-row: 2; grid-column: 2;" in Floki.attribute(robot_div, "style")
      assert "test" in Floki.attribute(robot_div, "phx-value-robot-id")
    end

    test "a robot has a health overlay" do
      robot = %{id: "test", player_id: "player_1", location: {1, 1}, hp: 50}

      {:ok, document} =
        render_to_string(RobotGameView, "robot.html", robot: robot, move: nil, selected: false)
        |> Floki.parse_document()

      assert [robot_health] = Floki.find(document, "#robot-#{robot.id}-health")
      assert "grid-row: 2; grid-column: 2;" in Floki.attribute(robot_health, "style")
      assert "50" == Floki.text(robot_health)
    end

    test "a robot without a move doesn't have a move div" do
      robot = %{id: "test", player_id: "player_1", location: {1, 1}, hp: 50}

      {:ok, document} =
        render_to_string(RobotGameView, "robot.html", robot: robot, move: nil, selected: false)
        |> Floki.parse_document()

      assert [] = Floki.find(document, "#robot-#{robot.id}-move")
    end

    test "a selected robot has the selected class" do
      robot = %{id: "test", player_id: "player_1", location: {1, 1}, hp: 50}

      {:ok, document} =
        render_to_string(RobotGameView, "robot.html", robot: robot, move: nil, selected: true)
        |> Floki.parse_document()

      assert [_robot] = Floki.find(document, ".robot.selected")
    end

    test "a robot with a move renders correctly" do
      robot = %{id: "test", player_id: "player_1", location: {1, 1}, hp: 50}
      move = %{robot_id: "test", type: :guard}

      {:ok, document} =
        render_to_string(RobotGameView, "robot.html", robot: robot, move: move, selected: false)
        |> Floki.parse_document()

      assert [move_html] = Floki.find(document, "#robot-#{robot.id}-move")
      assert "grid-row: 2; grid-column: 2;" in Floki.attribute(move_html, "style")
      assert RobotGameView.move_icon(move, robot.location) == Floki.text(move_html)
    end

    test "you can render all the types of moves" do
      robot = %{id: "test", player_id: "player_1", location: {1, 1}, hp: 50}

      [
        %{robot_id: "test", type: :guard},
        %{robot_id: "test", type: :suicide},
        %{robot_id: "test", type: :move, target: {1, 2}},
        %{robot_id: "test", type: :attack, target: {1, 2}}
      ]
      |> Enum.each(fn move ->
        {:ok, document} =
          render_to_string(RobotGameView, "robot.html", robot: robot, move: move, selected: false)
          |> Floki.parse_document()

        assert [move_html] = Floki.find(document, "#robot-#{robot.id}-move")
        assert RobotGameView.move_icon(move, robot.location) == Floki.text(move_html)
      end)
    end
  end

  describe "rendering the game header" do
    test "you can render the score board" do
      game = Game.new()

      {:ok, document} =
        render_to_string(RobotGameView, "game_header.html", game: game)
        |> Floki.parse_document()

      assert "TURN: 0 / 100" == Floki.find(document, ".turns") |> Floki.text()

      Enum.each(Floki.find(document, ".score .number"), fn score ->
        assert Floki.text(score) == "0"
      end)
    end

    test "it displays the correct turn" do
      game = Game.new(turn: 42, max_turns: 420)
      assert render_to_string(RobotGameView, "game_header.html", game: game) =~ "TURN: 42 / 420"
    end

    test "it displays the correct score" do
      robot_spawns = ~g/1 2/

      game =
        Game.new()
        |> Game.put_events(robot_spawns)

      {:ok, document} =
        render_to_string(RobotGameView, "game_header.html", game: game) |> Floki.parse_document()

      Enum.each(Floki.find(document, ".score .number"), fn score ->
        assert Floki.text(score) == "1"
      end)
    end
  end
end
