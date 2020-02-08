defmodule BattleBox.Lobby do
  use Ecto.Schema
  import Ecto.Changeset
  alias BattleBox.Repo
  alias __MODULE__.GameType

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @game_types Application.compile_env(:battle_box, [BattleBox.GameEngine, :games]) ||
                raise("Must set the :battle_box, BattleBox.GameEngine, :games config value")

  schema "lobbies" do
    field :name, :string
    field :game_type, GameType
    field :game_acceptance_timeout_ms, :integer, default: 500, virtual: true

    timestamps()
  end

  def changeset(lobby, params \\ %{}) do
    lobby
    |> cast(params, [
      :name,
      :game_type
    ])
    |> validate_required([:name, :game_type])
    |> validate_inclusion(:game_type, @game_types)
    |> validate_length(:name, min: 3, max: 50)
    |> unique_constraint(:name)
  end

  def get_by_name(name) do
    Repo.get_by(__MODULE__, name: name)
  end
end
