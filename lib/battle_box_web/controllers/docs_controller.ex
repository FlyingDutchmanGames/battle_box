defmodule BattleBoxWeb.DocsController do
  use BattleBoxWeb, :controller
  alias BattleBoxWeb.DocsView
  import BattleBox.InstalledGames, only: [installed_games: 0, game_type_name_to_module: 1]
  import BattleBox.Utilities.Humanize, only: [kebabify: 1, unkebabify: 1]

  @game_docs (for game <- installed_games(), into: %{} do
                {kebabify(game.title), game.docs_tree}
              end)

  @nav_tree %{
    "getting-started" => %{},
    "games" => @game_docs,
    "advanced" => %{
      "writing-a-client" => %{
        "a-simple-client" => %{}
      }
    }
  }

  def paths, do: unnest(@nav_tree)

  def docs(conn, %{"path" => path} = params) do
    render(conn, "documenation.html",
      nav_segments: nav_segments(conn, path),
      nav_options: nav_options(conn, path),
      content: content(path, params),
      params: params
    )
  end

  # Where the magic happens
  defp content(["games", game | rest], params) do
    module = game_type_name_to_module(game)

    template =
      case rest do
        [] -> "docs__index.html"
        rest -> "docs__#{Enum.join(rest, "__")}.html"
      end

    module.view_module.render(template, params: params)
  end

  defp content([], _params), do: DocsView.render("index.html")

  defp content(path, params),
    do: DocsView.render(Enum.join(path, "__") <> ".html", params: params)

  defp nav_segments(_conn, []), do: [:docs]

  defp nav_segments(conn, path) do
    segments =
      for i <- 1..length(path) do
        item = Enum.at(path, i - 1)
        to = Routes.docs_path(conn, :docs, Enum.take(path, i))
        {unkebabify(item), to}
      end

    [:docs | segments]
  end

  defp nav_options(conn, path) do
    opts = if path == [], do: @nav_tree, else: get_in(@nav_tree, path)

    for opt <- Map.keys(opts) do
      {unkebabify(opt), Routes.docs_path(conn, :docs, path ++ [opt])}
    end
  end

  defp unnest(subpath) do
    Enum.flat_map(subpath, fn {category, subcategories} ->
      [[category] | for(item <- unnest(subcategories), do: [category | item])]
    end)
  end
end
