defmodule BattleBox.Utilities.UserIdentifierValidation do
  import Ecto.Changeset

  # May only contain alphanumeric characters or hyphens.
  # Cannot begin or end with a hyphen.
  # Maximum is 39 characters.
  def validate_identifer(changeset, field_name) do
    changeset
    |> validate_required(field_name)
    |> validate_length(field_name, max: 39)
    |> validate_format(field_name, ~r/[a-zA-Z1-9-]/,
      message: "Can only contain alphanumeric characters or hyphens"
    )
    |> validate_format(field_name, ~r/^[^-]/, message: "Cannot start with a hyphen")
    |> validate_format(field_name, ~r/[^-]$/, message: "Cannot end with a hyphen")
  end
end
