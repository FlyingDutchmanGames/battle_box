defprotocol BattleBoxGame do
  @spec initialize(struct()) :: struct()
  def initialize(game)

  @spec disqualify(struct(), :player_1 | :player_2) :: struct()
  def disqualify(game, player)

  @spec over?(struct()) :: boolean()
  def over?(game)

  @spec settings(struct()) :: map()
  def settings(game)

  @spec commands_requests(struct()) :: map()
  def commands_requests(game)

  @spec calculate_turn(struct(), %{binary => any}) :: struct()
  def calculate_turn(game, moves)

  @spec score(struct()) :: %{binary => integer()}
  def score(game)

  @spec winner(struct()) :: binary | nil
  def winner(game)
end
