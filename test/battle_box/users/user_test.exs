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
    {:ok, _user} = create_user(username: "GrantJamesPowell")

    assert %User{username: "GrantJamesPowell"} = Repo.get_by(User, username: "GrantJamesPowell")
    assert %User{username: "GrantJamesPowell"} = Repo.get_by(User, username: "grantjamespowell")
    assert %User{username: "GrantJamesPowell"} = Repo.get_by(User, username: "GRANTJAMESPOWELL")
  end

  describe "upsert_from_github" do
    test "if there is nothing in the db it succeeds", context do
      assert {:ok, user} = User.upsert_from_github(context.user_from_github)
      assert not is_nil(user.id)
    end

    test "it will upsert the row if its called twice", context do
      assert {:ok, _} = User.upsert_from_github(context.user_from_github)
      user = Repo.get_by(User, github_id: context.user_from_github["id"])
      assert user.username == "GrantJamesPowell"

      assert {:ok, user2} =
               User.upsert_from_github(%{context.user_from_github | "login" => "pass"})

      assert user2.id == user.id
      assert user2.username == "pass"
    end
  end

  describe "anon_human_user/0" do
    test "If the anon user doesn't exist, this function will create it" do
      assert Repo.all(User) == []
      %User{username: "Anonymous", id: id} = User.anon_human_user()
      assert [%{username: "Anonymous", id: ^id}] = Repo.all(User)
    end

    test "you can make multiple calls to `anon_human_user`" do
      assert %User{username: "Anonymous", id: id} = User.anon_human_user()
      assert %User{username: "Anonymous", id: ^id} = User.anon_human_user()
    end
  end

  describe "system_user/0" do
    test "If the system user doesn't exist, this function will create it" do
      assert Repo.all(User) == []
      %User{username: "Botskrieg", id: id} = User.system_user()
      assert [%{username: "Botskrieg", id: ^id}] = Repo.all(User)
    end

    test "you can make multiple calls to `system_user`" do
      assert %User{username: "Botskrieg", id: id} = User.system_user()
      assert %User{username: "Botskrieg", id: ^id} = User.system_user()
    end
  end
end
