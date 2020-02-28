# BattleBox

## Hitlist

[x] Make the `Game.robots` function more efficent by denormalizing a `game.robots_at_turn` to be a `%{turn_num => [robot]}`
[ ] Get factory bot for elixir installed and working (its becoming too hard to mock data)
[ ] Rename (battle box game) => (game), (battle box game bot) => (game bot), (robot game game) => (robot game)
[ ] User controller
[ ] Reorganize the game engine
[ ] Downloads controller, and `as_downloadable` as part of the game protocol
[ ] Sequential Turn Support for the Player Server / Refactor moves requests to be able to contain multiple players
[ ] Github actions
  [ ] Spec Suite
  [ ] Build docker images
  [ ] Prod pulls docker images and runs them via a system service
  [ ] Github Action updates Prod
[ ] Visualize games better (include moves and historical turns)
  [x] Key through turns, and have turns be sharable via url
  [ ] Changing a turn does not affect history api so its easier to use back button
[ ] A decent bot implmentation for testing
[ ] Cinematic Move Delay to make certain lobbies more fun to watch
[ ] historical games page
  [x] Get something in the page
  [ ] Efficent Pagination
  [ ] Filter by (lobby id, user id, bot id)
  [ ] Arrow key navigation through pages
[ ] write move timeout ms onto the lobby settings
[ ] live games page
[ ] Bot Info Page
[ ] Game Engine Stats Server (# Live Games, # Most Active Lobby, # Connections)?
[ ] Tear out phoenix pubsub for game engine pubsub and use registry
[ ] Remove GenStateMachine in favor of built in :genstatem (this is annoying so maybe not)
[ ] bot self play/user self play lobby matchmaker settings
[ ] Github Pages landing page
[x] Pick a domain name and associate it (botskrieg.com)
[ ] BattleBox Elixir Client
[ ] envsubt in ubuntu setup to deal with changing hostnames
[ ] tar ball for release, maybe build on mac? systemd service for server
[ ] postgres superadmin user doesn't exist?
[x] Lobby CRUD
[x] Handle Move Timeout errors (find a way to test?)
[x] Break out Game Settings
[x] Battle Box Game Table (ID, Players, Lobby, Winner, timestamps) Index [(insertedat desc), (gin players), (lobby id)]
[ ] players > 2 game mode
[ ] sequential turn mode
[ ] SuperAdmin
[ ] Handle when connection is closed on trying to send from connection server
[ ] TCP server inside of game engine??
[x] Move Parser
[ ] Connection Debugger
[ ] Element Storybook
[ ] Conncurrent connection limiter
