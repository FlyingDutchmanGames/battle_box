defmodule BattleBox.LobbyTest do
  use BattleBox.DataCase
  alias BattleBox.User

  setup do
    %{
      user_from_github: %{
        "id" => 1,
        "html_url" => "test.com",
        "login" => "GrantJamesPowell",
        "name" => "Grant Powell",
        "avatar_url" => "test-avatar.com",
        "access_token" => "1234"
      }
    }
  end

  describe "upsert_from_github" do
    test "if there is nothing in the db it succeeds", context do
      assert {:ok, user} = User.upsert_from_github(context.user_from_github)
      assert not is_nil(user.id)
    end

    test "it will upsert the row if its called twice", context do
      assert {:ok, _} = User.upsert_from_github(context.user_from_github)
      user = User.get_by_github_id(context.user_from_github["id"])
      assert user.name == "Grant Powell"
      assert {:ok, _} = User.upsert_from_github(%{context.user_from_github | "name" => "pass"})
      user = User.get_by_github_id(context.user_from_github["id"])
      assert user.name == "pass"
    end
  end
end
