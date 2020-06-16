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
      {[], nil, "/ "},
      {["foo"], [], "/ foo /"},
      {[{"foo", "bar"}], [], "/ foo /"},
      {[], [{"foo", ""}], "/ { foo, }"},
      {[], [{"foo", ""}, {"bar", ""}], "/ { foo, bar, }"},
      # User
      {[@user], [], "/ Users / example-username /"},
      {[{@user, :bots}], [], "/ Users / example-username / Bots /"},
      {[{@user, :keys}], [], "/ Users / example-username / Keys /"},
      {[{@user, :arenas}], [], "/ Users / example-username / Arenas /"},
      # Resources
      {[@bot], [], "/ Users / example-username / Bots / example-bot /"},
      {[@arena], [], "/ Users / example-username / Arenas / example-arena /"},
      # Admin
      {[:admin], [], "/ Admin /"},
      {[:admin, {:admin, @user}], [], "/ Admin / Users / example-username /"},
      # Options
      {[], [{:new, :bot}], "/ { New, }"},
      {[], [{:new, :arena}], "/ { New, }"},
      {[], [{:new, :api_key}], "/ { New, }"},
      {[], [{:edit, @bot}], "/ { Edit, }"},
      {[], [{:edit, @arena}], "/ { Edit, }"},
      {[], [{:admin, {:edit, @user}}], "/ { Edit, }"},
      {[], [{:games, @bot}], "/ { Games, }"},
      {[], [{:games, @user}], "/ { Games, }"},
      {[], [{:games, @arena}], "/ { Games, }"},
      {[], [{:follow, @bot}], "/ { Follow, }"},
      {[], [{:follow, @user}], "/ { Follow, }"},
      {[], [{:follow, @arena}], "/ { Follow, }"},
      {[], [{:inaccessible, "foo"}], "/ { foo, }"}
    ]
    |> Enum.each(fn {nav_segments, nav_options, expected} ->
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
    end)
  end
end
