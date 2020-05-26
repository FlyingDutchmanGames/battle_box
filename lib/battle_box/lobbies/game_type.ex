defmodule BattleBox.GameType do
  use Ecto.Type
  def type, do: :string

  @game_types Application.get_env(:battle_box, BattleBox.GameEngine)[:games] ||
                raise("Must set the :battle_box, BattleBox.GameEngine, :games config value")

  @game_types
  |> Enum.each(fn game_type ->
    string_type = game_type.db_name()
    def cast(unquote(string_type)), do: {:ok, unquote(game_type)}
    def cast(unquote(game_type)), do: {:ok, unquote(game_type)}
    def load(unquote(string_type)), do: {:ok, unquote(game_type)}
    def dump(unquote(game_type)), do: {:ok, unquote(string_type)}
  end)

  def game_types, do: @game_types
end
