defmodule BattleBox.Utilities.UserIdentifierValidationTest do
  import BattleBox.Utilities.UserIdentifierValidation, only: [validate_identifer: 2]
  alias BattleBox.Bot
  import Ecto.Changeset
  use ExUnit.Case

  test "identifers follow the rules" do
    [
      # Invalid Identifiers
      {"", {"can't be blank", [validation: :required]}},
      {"-foo", {"Cannot start with a hyphen", [validation: :format]}},
      {"foo-", {"Cannot end with a hyphen", [validation: :format]}},
      {"😃", {"Can only contain alphanumeric characters or hyphens", [validation: :format]}},
      {:binary.copy("a", 40),
       {"should be at most %{count} character(s)",
        [count: 39, validation: :length, kind: :max, type: :string]}},
      # Valid Identifiers
      {"foo", nil},
      {"foo-bar", nil}
    ]
    |> Enum.each(fn {name, errors} ->
      changeset =
        %Bot{}
        |> change(%{name: name})
        |> validate_identifer(:name)

      assert changeset.errors[:name] == errors
    end)
  end
end
