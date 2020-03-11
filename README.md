# BattleBox

## Hitlist

V1
====
[x] Bots Live Page
  [x] Show a user's bots
  [ ] Show the bot servers active for each bot
  [ ] Show recent games for each bot
[ ] Deal with move timeouts
  [ ] We should tell people when they miss a timeout?
  [ ] dealing with closed sockets
```
GenStateMachine {GameEngine.Connection.Registry, "4ce89f99-075b-4f2a-bf3c-5ed1d32873e4", %{game_id: nil, started_at: ~U[2020-03-11 05:15:3
 ** (MatchError) no match of right hand side value: {:error, :closed}
     (battle_box 0.1.0) lib/battle_box/tcp_connection_server/connection_handler.ex:188: BattleBox.TcpConnectionServer.ConnectionHandler.send_to_socket/2
     (battle_box 0.1.0) lib/battle_box/tcp_connection_server/connection_handler.ex:149: BattleBox.TcpConnectionServer.ConnectionHandler.handle_event/4
     (stdlib 3.11.2) gen_statem.erl:1161: :gen_statem.loop_state_callback/11
     (stdlib 3.11.2) proc_lib.erl:249: :proc_lib.init_p_do_apply/3
```
 [ ] deal with invalid moves submission
```
 ** (MatchError) no match of right hand side value: {:error, :invalid_moves_submission}
     (battle_box 0.1.0) lib/battle_box/tcp_connection_server/connection_handler.ex:114: BattleBox.TcpConnectionServer.ConnectionHandler.handle_event/4
     (stdlib 3.11.2) gen_statem.erl:1161: :gen_statem.loop_state_callback/11
     (stdlib 3.11.2) proc_lib.erl:249: :proc_lib.init_p_do_apply/3
```
[ ] Get factory bot for elixir installed and working (its becoming too hard to mock data)
[ ] Bot Server Follow Flow
[ ] More Efficent Robot Game Representation
  [x] Super high memory usage in lobby liveview, likely due to pulling multiple games into memory
  [x] break out the live game data from the live game metadata, most places (lobby live) only need live game metadad
  [ ] limit memory usage of game servers (they're currently at 2 mbs)
  [ ] Binary representation of robot game events
  [ ] Binary representation of terrain (would be nice if was a literal)
  [ ] Manual GC?
[ ] switch game server to be 100% defdelegate
[ ] Lobby Page
  [x] Show Live Games
  [x] Add score to in game server registry metadata
  [ ] Link to historical games
[ ] Hide `robot_game` from matchmaker logic and game server by putting it in `BattleBox.Game`
[ ] url identifiers
  [ ] `/users/grantjamespowell`
  [ ] `/users/grantjamespowell/bots`
  [ ] `/users/grantjamespowell/bots/foo`
  [ ] `/users/grantjamespowell/*`
  [ ] `/users/grantjamespowell/lobbies/foo`
  [ ] `/lobbies/foo`
[ ] historical games page
  [ ] Get something in the page
  [ ] Efficent Pagination
  [ ] Filter by (lobby id, user id, bot id)
  [ ] Arrow key navigation through pages
[ ] live games page (Probably works via the historical game pages html/css?)
[ ] Static Site
  [ ] Wire protocol docs
  [ ] Robot game rules docs
[ ] Lobby settings passed correctly
  [ ] bot self play allowed toggle
  [ ] user self play allowed toggle
  [x] Delay moves until alloted time/submit as fast as possible setting
  [x] write move timeout ms onto the lobby settings
[ ] Bot Info Page
[ ] BattleBox Elixir Client
[ ] Visualize games better (include moves and historical turns)
  [x] Key through turns, and have turns be sharable via url
  [ ] Changing a turn does not affect history api so its easier to use back button
[ ] Game Engine Stats Server (# Live Games, # Most Active Lobby, # Connections)?

Nice to Haves
======
[ ] Matchmaker page
[ ] Handle when connection is closed on trying to send from connection server
[ ] SuperAdmin
[ ] A decent bot implmentation for testing
[ ] Connection Debugger (this has some issues due to amount of messages...)
[ ] Element Storybook
[ ] Concurrent connection limiter
[ ] Downloads controller, and `as_downloadable` as part of the game protocol
[ ] Google Analytics on the github page

Done
=======
[x] Make bot server announce bot server start
[x] Pass the bot object into the matchmaker
[x] Bot Server Registry Improvements
[x] Client starts the convo
[x] Length framed messages
[x] Github actions Spec Suite
[x] Switch to dockerized production app
  [x] Create a prod docker file
  [x] rebuild prod server from docker image
  [x] envsubt in ubuntu setup to deal with changing hostnames
[x] Have the Game Servers put the `Game` into the registry, and pass around `game.id`s instead of `robot_game.ids`
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
[x] Sequential turn mode
[x] players > 2 game mode
[x] Domain Name
  [x] pick one
  [x] www. to github pages
  [x] Point domain to servers
