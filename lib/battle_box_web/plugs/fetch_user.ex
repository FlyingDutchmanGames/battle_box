defmodule BattleBoxWeb.Plugs.FetchUser do
  alias BattleBox.{Repo, User}
  import Plug.Conn

  def init(_), do: :not_used

  def call(conn, _config) do
    with id when not is_nil(id) <- get_session(conn, "user_id"),
         %User{} = user <- Repo.get(User, id) do
      assign(conn, :current_user, user)
    else
      _ ->
        assign(conn, :current_user, nil)
    end
  end
end
