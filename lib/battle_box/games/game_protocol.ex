defprotocol BattleBoxGame do
  def calculate_turn(game, moves)
  def commands_requests(game)
  def disqualify(game, player)
  def initialize(game)
  def over?(game)
  def score(game)
  def settings(game)
  def turn_info(game)
  def winner(game)
end
