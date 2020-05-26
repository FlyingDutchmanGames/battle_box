defmodule BattleBox.GameType do
  use Ecto.Type
  import BattleBox.InstalledGames

  def type, do: :string

  for game <- installed_games() do
    def cast(unquote("#{game.name}")), do: {:ok, unquote(game)}
    def cast(unquote(game)), do: {:ok, unquote(game)}
    def load(unquote("#{game.name}")), do: {:ok, unquote(game)}
    def dump(unquote(game)), do: {:ok, unquote("#{game.name}")}
  end
end
