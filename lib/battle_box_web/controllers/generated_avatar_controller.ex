defmodule BattleBoxWeb.GeneratedAvatarController do
  use BattleBoxWeb, :controller
  require EEx

  EEx.function_from_string(
    :def,
    :generated_avatar,
    """
      <svg  xmlns="http://www.w3.org/2000/svg"
            xmlns:xlink="http://www.w3.org/1999/xlink" width="100" height="100">
        <rect x="0" y="0" width="100" height="100" fill="#4a195a"/>
        <text
          x="50%"
          y="50%"
          dominant-baseline="middle"
          text-anchor="middle"
          fill="white"
          style="font-family: Ruda,sans-serif; font-weight: bold;"><%= username %></text>
      </svg>
    """,
    [:username]
  )

  def avatar(conn, %{"username" => username}) do
    avatar = generated_avatar(username)

    conn
    |> put_resp_content_type("image/svg+xml")
    |> send_resp(200, avatar)
  end
end
