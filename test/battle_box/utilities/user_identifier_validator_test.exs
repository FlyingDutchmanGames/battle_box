defmodule BattleBox.Utilities.UserIdentifierValidationTest do
  import BattleBox.Utilities.UserIdentifierValidation,
    only: [validate_user_identifer: 1, validate_user_identifer: 2]

  alias BattleBox.Bot
  import Ecto.Changeset
  use ExUnit.Case

  @test_cases [
    # Invalid Identifiers
    {"", {"can't be blank", [validation: :required]}},
    {"-foo", {"Cannot start with a hyphen", [validation: :format]}},
    {"foo-", {"Cannot end with a hyphen", [validation: :format]}},
    {"😃", {"Can only contain alphanumeric characters or hyphens", [validation: :format]}},
    {"foo😃bar", {"Can only contain alphanumeric characters or hyphens", [validation: :format]}},
    {:binary.copy("a", 40),
     {"should be at most %{count} character(s)",
      [count: 39, validation: :length, kind: :max, type: :string]}},
    {"spaces test",
     {"Can only contain alphanumeric characters or hyphens", [validation: :format]}},
    {"foo--bar", {"Cannot contain two hyphens in a row", []}},
    {"new", {"Cannot be \"new\"", []}},
    {"index", {"Cannot be \"index\"", []}},
    {"edit", {"Cannot be \"edit\"", []}},
    # Valid Identifiers
    {"foo", nil},
    {"foo-bar", nil},
    {"0123456789", nil},
    {"abcdefghijklmnopqrstuvwxyz", nil},
    {"ABCDEFGHIJKLMNOPQRSTUVWXYZ", nil}
  ]

  test "you can use it on raw strings" do
    @test_cases
    |> Enum.each(fn
      {name, nil} ->
        assert validate_user_identifer(name) == :ok

      {name, {error, _}} ->
        assert {:error, returned_errors} = validate_user_identifer(name)
        assert error in returned_errors
    end)
  end

  test "identifers follow the rules when used in changesets" do
    for {name, errors} <- @test_cases do
      changeset =
        change(%Bot{}, %{name: name})
        |> validate_user_identifer(:name)

      assert changeset.errors[:name] == errors,
             "#{name} should yield #{inspect(errors)}, but instead is #{
               inspect(changeset.errors[:name])
             }"
    end
  end
end
