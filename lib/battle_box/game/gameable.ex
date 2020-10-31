defprotocol BattleBox.Game.Gameable do
  @type game :: map()
  @type player :: integer()

  @spec calculate_turn(game, moves :: any()) :: game
  def calculate_turn(game, moves)

  @spec commands_requests(game) :: %{optional(player) => map()}
  def commands_requests(game)

  @spec disqualify(game, player) :: game
  def disqualify(game, player)

  @spec initialize(game) :: game
  def initialize(game)

  @spec over?(map()) :: boolean()
  def over?(game)

  @spec score(game :: game) :: %{required(player) => integer()}
  def score(game)

  @spec settings(game) :: map()
  def settings(game)

  @spec winner(game) :: nil | player
  def winner(game)

  def turn_info(game)
end
