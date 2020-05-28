defmodule BattleBox.Bot do
  alias BattleBox.{Repo, User, Game}
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "bots" do
    field :name, :string
    many_to_many :games, Game, join_through: "game_bots"
    belongs_to :user, User
    timestamps()
  end

  def get_or_create_by_name(user, name) do
    # Below is the ideal implementation of this function.
    # At the current time (May 27, 2020, ecto 3.4.3),
    # `returning: true` does not properly return the id in the case where
    # the conflict was hit, likely due to the binary id autogenerate, it returns the autogen'd ID
    # of the changeset
    #
    # user
    # |> Ecto.build_assoc(:bots)
    # |> changeset(%{name: name})
    # |> Repo.insert(returning: true, on_conflict: :nothing, conflict_target: [:user_id, :name])

    user
    |> Ecto.build_assoc(:bots)
    |> changeset(%{name: name})
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:user_id, :name])
    |> case do
      {:ok, _bot} ->
        # Must reload to get the correct ID when bot wasn't created
        {:ok, Repo.get_by!(__MODULE__, name: name, user_id: user.id)}

      {:error, _err} = err ->
        err
    end
  end

  def changeset(bot, params \\ %{}) do
    bot
    |> cast(params, [:name])
    |> validate_required(:name)
    |> validate_length(:name, max: 20)
    |> unique_constraint(:name,
      name: :bots_user_id_name_index,
      message: "Bot with that name already exists for your user"
    )
  end
end
