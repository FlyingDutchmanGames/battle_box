# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     BattleBox.Repo.insert!(%BattleBox.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias BattleBox.Games.RobotGame.Game
alias BattleBox.Repo

player_1 = "2a8bdb74-916b-4712-91f7-0e150e744d3e"
player_2 = "8c6ea4ce-76ce-4604-9c9c-e47010ef8258"

{:ok, _} =
  Game.new(
    player_1: player_1,
    player_2: player_2,
    id: "0f7a7d2c-86a8-4a43-a466-5e7c74001dd8"
  )
  |> Game.changeset()
  |> Repo.insert_or_update()
