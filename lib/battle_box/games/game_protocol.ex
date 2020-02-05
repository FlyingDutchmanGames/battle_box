defprotocol BattleBoxGame do
  @spec id(struct()) :: Ecto.UUID.t()
  def id(game)

  @spec turn(struct()) :: non_neg_integer()
  def turn(game)

  @spec disqualify(struct(), :player_1 | :player_2) :: struct()
  def disqualify(game, player)

  @spec over?(struct()) :: boolean()
  def over?(game)

  @spec persist(struct()) :: {:ok, struct()}
  def persist(game)

  @spec settings(struct()) :: map()
  def settings(game)

  @spec moves_request(struct) :: map()
  def moves_request(game)

  @spec calculate_turn(struct(), %{optional(:player_1) => [any], optional(:player_2) => [any]}) :: struct()
  def calculate_turn(game, moves)
end
