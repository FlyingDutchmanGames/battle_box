defmodule BattleBox.Utilities.UserIdentifierValidation do
  import Ecto.Changeset

  @disallowed_words ~w(
    new
    license
    edit
    update
    show
    create
    index
    robots
  )

  # May only contain alphanumeric characters or hyphens.
  # Cannot begin or end with a hyphen.
  # Cannot have two hypens in a row
  # Maximum is 39 characters.
  # Cannot be in the reserved words
  def validate_user_identifer(identifier) when is_binary(identifier) do
    changeset =
      {%{}, %{identifier: :string}}
      |> Ecto.Changeset.cast(%{identifier: identifier}, [:identifier])
      |> validate_user_identifer(:identifier)

    if changeset.errors == [],
      do: :ok,
      else: {:error, for({:identifier, {msg, _}} <- changeset.errors, do: msg)}
  end

  def validate_user_identifer(changeset, field_name) do
    changeset
    |> validate_required(field_name)
    |> validate_length(field_name, max: 39)
    |> validate_format(field_name, ~r/^[a-zA-Z0-9-]+$/,
      message: "Can only contain alphanumeric characters or hyphens"
    )
    |> validate_change(field_name, fn ^field_name, value ->
      downcased = String.downcase(value)
      for word <- @disallowed_words, word == downcased, do: {field_name, "Cannot be \"#{word}\""}
    end)
    |> validate_change(field_name, fn ^field_name, value ->
      if Regex.match?(~r/--/, value),
        do: [{field_name, "Cannot contain two hyphens in a row"}],
        else: []
    end)
    |> validate_format(field_name, ~r/^[^-]/, message: "Cannot start with a hyphen")
    |> validate_format(field_name, ~r/[^-]$/, message: "Cannot end with a hyphen")
  end
end
