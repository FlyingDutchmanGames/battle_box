# BattleBox

## Hitlist

V1
====
[ ] Have the Game Servers put the `Game` into the registry, and pass around `game.id`s instead of `robot_game.ids`
[ ] Get factory bot for elixir installed and working (its becoming too hard to mock data)
[ ] Lobby settings passed correctly
  [ ] bot self play allowed toggle
  [ ] user self play allowed toggle
  [ ] Delay moves until alloted time/submit as fast as possible setting
  [ ] write move timeout ms onto the lobby settings
[ ] Static Site
  [ ] Wire protocol docs
  [ ] Robot game rules docs
[ ] players > 2 game mode / sequential turn mode
[ ] Domain Name
  [x] pick one
  [ ] Point domain to servers
[ ] historical games page
  [x] Get something in the page
  [ ] Efficent Pagination
  [ ] Filter by (lobby id, user id, bot id)
  [ ] Arrow key navigation through pages
[ ] live games page
[ ] Bot Info Page
[ ] BattleBox Elixir Client
[ ] Visualize games better (include moves and historical turns)
  [x] Key through turns, and have turns be sharable via url
  [ ] Changing a turn does not affect history api so its easier to use back button
[ ] Switch to dockerized production app
  [ ] Create a prod docker file
  [ ] rebuild prod server from docker image
  [ ] envsubt in ubuntu setup to deal with changing hostnames
[ ] Game Engine Stats Server (# Live Games, # Most Active Lobby, # Connections)?

Nice to Haves
======
[ ] Handle when connection is closed on trying to send from connection server
[ ] SuperAdmin
[ ] A decent bot implmentation for testing
[ ] Connection Debugger
[ ] Element Storybook
[ ] Conncurrent connection limiter
[ ] Github actions Spec Suite
[ ] Downloads controller, and `as_downloadable` as part of the game protocol

Done
=======
[x] Refactor the save strategy for games/robot games
[x] Rename (battle box game) => (game), (battle box game bot) => (game bot), (robot game game) => (robot game)
[x] Reorganize the game engine
[x] Make the `Game.robots` function more efficent by denormalizing a `game.robots_at_turn` to be a `%{turn_num => [robot]}`
[x] Move Parser
[x] Lobby CRUD
[x] Handle Move Timeout errors (find a way to test?)
[x] Break out Game Settings
[x] Battle Box Game Table (ID, Players, Lobby, Winner, timestamps) Index [(insertedat desc), (gin players), (lobby id)]
[x] User controller
[x] Tear out phoenix pubsub for game engine pubsub and use registry
