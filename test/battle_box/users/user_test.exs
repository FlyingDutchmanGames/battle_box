defmodule BattleBox.UserTest do
  use BattleBox.DataCase
  alias BattleBox.{User, Repo}

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

  test "names are case insensitive" do
    {:ok, _user} = create_user(user_name: "GrantJamesPowell")

    assert %User{user_name: "GrantJamesPowell"} = Repo.get_by(User, user_name: "GrantJamesPowell")
    assert %User{user_name: "GrantJamesPowell"} = Repo.get_by(User, user_name: "grantjamespowell")
    assert %User{user_name: "GrantJamesPowell"} = Repo.get_by(User, user_name: "GRANTJAMESPOWELL")
  end

  describe "upsert_from_github" do
    test "if there is nothing in the db it succeeds", context do
      assert {:ok, user} = User.upsert_from_github(context.user_from_github)
      assert not is_nil(user.id)
    end

    test "it will upsert the row if its called twice", context do
      assert {:ok, _} = User.upsert_from_github(context.user_from_github)
      user = Repo.get_by(User, github_id: context.user_from_github["id"])
      assert user.user_name == "GrantJamesPowell"

      assert {:ok, user2} =
               User.upsert_from_github(%{context.user_from_github | "login" => "pass"})

      assert user2.id == user.id
      assert user2.user_name == "pass"
    end
  end

  describe "set_ban_status" do
    test "you can ban and unban people" do
      {:ok, user} = create_user(%{is_banned: true})
      assert user.is_banned

      {:ok, _user} = User.set_ban_status(user, false)
      user = Repo.get(User, user.id)
      refute user.is_banned

      {:ok, _user} = User.set_ban_status(user, true)
      user = Repo.get(User, user.id)
      assert user.is_banned
    end
  end
end
