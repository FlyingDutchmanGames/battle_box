defmodule BattleBox.Bot do
  alias BattleBox.{Repo, User, Game}
  use Ecto.Schema
  import Ecto.Changeset
  import BattleBox.Utilities.UserIdentifierValidation, only: [validate_user_identifer: 2]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "bots" do
    field :name, :string
    many_to_many :games, Game, join_through: "game_bots"
    belongs_to :user, User
    timestamps()
  end

  @spec human_bot(%User{}) :: {:ok, %__MODULE__{}}
  def human_bot(%User{} = user), do: get_or_create_by_name(user, "Human")

  @spec anon_human_bot() :: {:ok, %__MODULE__{}}
  def anon_human_bot() do
    {:ok, bot} = get_or_create_by_name(User.anon_human_user(), "Human")
    bot = Repo.preload(bot, :user)
    {:ok, bot}
  end

  @spec system_bot(String.t()) :: {:ok, %__MODULE__{}}
  def system_bot(name) do
    {:ok, bot} = get_or_create_by_name(User.system_user(), name)
    bot = Repo.preload(bot, :user)
    {:ok, bot}
  end

  @spec get_or_create_by_name(%User{}, String.t()) ::
          {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
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
    |> validate_user_identifer(:name)
    |> unique_constraint(:name,
      name: :bots_user_id_name_index,
      message: "Bot with that name already exists for your user"
    )
  end
end
