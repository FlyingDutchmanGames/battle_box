defmodule BattleBoxWeb.Templates.BreadCrumbsTest do
  use ExUnit.Case, async: true
  alias BattleBoxWeb.PageView
  alias BattleBox.{User, Arena, Bot}

  @user %User{username: "example-username"}
  @bot %Bot{user: @user, name: "example-bot"}
  @arena %Arena{user: @user, name: "example-arena"}

  test "it renders the breadcrumbs correctly" do
    [
      # The Basics
      {[], nil, "/ ", ["/"]},
      {["foo"], [], "/ foo /", ["/"]},
      {[{"foo", "/to/foo"}], [], "/ foo /", ["/", "/to/foo"]},
      {[], [{"foo", "/to/foo"}], "/ { foo, }", ["/", "/to/foo"]},
      {[], [{"foo", "/to/foo"}, {"bar", "/to/bar"}], "/ { foo, bar, }",
       ["/", "/to/foo", "/to/bar"]},
      {[], [{:inaccessible, "foo"}], "/ { foo, }", ["/"]},
      # User
      {[@user], [], "/ Users / example-username /", ["/", "/users", "/users/example-username"]},
      {[{@user, :bots}], [], "/ Users / example-username / Bots /",
       ["/", "/users", "/users/example-username", "/users/example-username/bots"]},
      {[{@user, :keys}], [], "/ Users / example-username / Keys /",
       ["/", "/users", "/users/example-username", "/keys"]},
      {[{@user, :arenas}], [], "/ Users / example-username / Arenas /",
       ["/", "/users", "/users/example-username", "/users/example-username/arenas"]},
      # Resources
      {[@bot], [], "/ Users / example-username / Bots / example-bot /",
       [
         "/",
         "/users",
         "/users/example-username",
         "/users/example-username/bots",
         "/users/example-username/bots/example-bot"
       ]},
      {[@arena], [], "/ Users / example-username / Arenas / example-arena /",
       [
         "/",
         "/users",
         "/users/example-username",
         "/users/example-username/arenas",
         "/users/example-username/arenas/example-arena"
       ]},
      # Admin
      {[:admin], [], "/ Admin /", ["/", "/admin"]},
      {[:admin, {:admin, @user}], [], "/ Admin / Users / example-username /",
       ["/", "/admin", "/admin/users", "/admin/users/example-username"]},
      # Options
      {[], [{:new, :bot}], "/ { New, }", ["/", "/bots/new"]},
      {[], [{:new, :arena}], "/ { New, }", ["/", "/arenas/new"]},
      {[], [{:new, :api_key}], "/ { New, }", ["/", "/keys/new"]},
      {[], [{:edit, @bot}], "/ { Edit, }",
       ["/", "/users/example-username/bots/example-bot/edit"]},
      {[], [{:edit, @arena}], "/ { Edit, }",
       ["/", "/users/example-username/arenas/example-arena/edit"]},
      {[], [{:admin, {:edit, @user}}], "/ { Edit, }",
       ["/", "/admin/users/example-username/edit"]},
      {[], [{:games, @bot}], "/ { Games, }",
       ["/", "/users/example-username/bots/example-bot/games"]},
      {[], [{:games, @user}], "/ { Games, }", ["/", "/users/example-username/games"]},
      {[], [{:games, @arena}], "/ { Games, }",
       ["/", "/users/example-username/arenas/example-arena/games"]},
      {[], [{:follow, @bot}], "/ { Follow, }",
       ["/", "/users/example-username/bots/example-bot/follow"]},
      {[], [{:follow, @user}], "/ { Follow, }", ["/", "/users/example-username/follow"]},
      {[], [{:follow, @arena}], "/ { Follow, }",
       ["/", "/users/example-username/arenas/example-arena/follow"]}
    ]
    |> Enum.each(fn {nav_segments, nav_options, expected, links} ->
      {:safe, io_list} =
        PageView.render("_bread_crumbs.html",
          conn: BattleBoxWeb.Endpoint,
          segments: nav_segments,
          options: nav_options
        )

      html = IO.iodata_to_binary(io_list)
      {:ok, document} = Floki.parse_document(html)

      assert expected ==
               document
               |> Floki.text()
               |> (&Regex.replace(~r/\n/, &1, "")).()
               |> (&Regex.replace(~r/\s+/, &1, " ")).()

      assert links ==
               document
               |> Floki.find("a")
               |> Enum.flat_map(&Floki.attribute(&1, "href"))
    end)
  end
end
