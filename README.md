# BattleBox

## The OpenSource Bot Battle Platform

### What is BattleBox?

BattleBox has three pieces

#### BattleBox Games

A `BattleBox.Game` is a set of modules that implement the BattleBox Game Interface and Behaviour, and can be run by BattleBox Core.

#### BattleBox Core

A set of standalone libraries for running battlebox games. (Everything under the `BattleBox.GameEngine` module namespace)

#### Botskrieg

A Phoenix app that allows for UI and API driven use of the Game Engine

## SETUP

1.) Get your credentials in github and make a `dev.secret.exs` based on `dev.secret.exs.example` 
  * Use `http://localhost:4000/auth/github/callback` as your callback url

## TODO

### V1

- [ ] Styling
  - [x] Pick some colors
  - [x] Pick a font
  - [x] Rebrand everything to botskrieg
  - [ ] Bots Live Page
- [ ] Top level navigation
  - [x] Bots
  - [x] Lobbies
  - [ ] Games
- [ ] Live Games Page
   - [ ] Show winner
   - [ ] Show moves
    - [ ] Move
    - [ ] Guard
    - [ ] Suicide
    - [ ] Attack
- [ ] Make sure user input can't cause a game to crash
- [ ] More Efficent Robot Game Representation
  - [x] Super high memory usage in lobby liveview, likely due to pulling multiple games into memory
  - [x] break out the live game data from the live game metadata, most places (lobby live) only need live game metadad
  - [x] Binary representation of robot game events
  - [x] Binary representation of terrain (would be nice if was a literal)
  - [ ] limit memory usage of game servers (they're currently at 2 mbs)
  - [ ] Manual GC?
- [ ] Lobby Page
  - [x] Show Live Games
  - [x] Add score to in game server registry metadata
  - [ ] Link to historical games
- [ ] historical games page
   - [ ] Get something in the page
   - [ ] Efficent Pagination
   - [ ] Filter by (lobby id, user id, bot id)
 - [ ] live games page (Probably works via the historical game pages html/css?)
 - [ ] Static Site
  - [ ] Wire protocol docs
  - [ ] Robot game rules docs
- [ ] Lobby settings passed correctly
  - [ ] bot self play allowed toggle
  - [ ] user self play allowed toggle
  - [x] Delay moves until alloted time/submit as fast as possible setting
  - [x] write move timeout ms onto the lobby settings
- [ ] Bot Info Page
- [ ] BattleBox Elixir Client
- [ ] BattleBox Python Client
- [ ] Visualize games better (include moves and historical turns)
  - [x] Key through turns, and have turns be sharable via url
  - [ ] Changing a turn does not affect history api so its easier to use back button
- [ ] Remove row-min/max from terrain, because everything must be 0 indexed
- [ ] Enforce ASCII < 12 chars no spaces/special in names of everythin
- [ ] Make the end turns the number of turns in the game
- [ ] Switch bot tokens to user tokens

### Nice to Haves

- [ ] Matchmaker page
- [ ] Handle when connection is closed on trying to send from connection server
- [ ] A decent bot implmentation for testing
- [ ] Connection Debugger (this has some issues due to amount of messages...)
- [ ] Element Storybook
- [ ] Concurrent connection limiter
- [ ] Downloads controller, and `as_downloadable` as part of the game protocol
- [ ] Google Analytics on the github page
- [ ] Terrain Editor
- [ ] Game Engine Stats Server/Interface (# Live Games, # Most Active Lobby, # Connections)?
- [ ] Build TicTacToe as proof of game engine extendability
- [ ] `mix battle_box.swarm {optional credentials file}` task to run a swarm against a botskrieg server for regression testing
- [ ] Get factory bot for elixir installed and working (its becoming too hard to mock data)
- [ ] Pass timing info to the game so it can do move timing

### Done

- [x] Bots Live Page
  - [x] Show a user's bots
  - [x] Show the bot servers active for each bot
- [x] switch game server to be 100% defdelegate
- [x] Hide `robot_game` from matchmaker logic and game server by putting it in `BattleBox.Game`
- [x] Bot Server Follow Flow
- [x] Make bot server announce bot server start
- [x] Pass the bot object into the matchmaker
- [x] Bot Server Registry Improvements
- [x] Client starts the convo
- [x] Length framed messages
- [x] Github actions Spec Suite
- [x] Signout
- [x] Switch to dockerized production app
  - [x] Create a prod docker file
  - [x] rebuild prod server from docker image
  - [x] envsubt in ubuntu setup to deal with changing hostnames
- [x] Have the Game Servers put the `Game` into the registry, and pass around `game.id`s instead of `robot_game.ids`
- [x] Refactor the save strategy for games/robot games
- [x] Rename (battle box game) => (game), (battle box game bot) => (game bot), (robot game game) => (robot game)
- [x] Reorganize the game engine
- [x] Make the `Game.robots` function more efficent by denormalizing a `game.robots_at_turn` to be a `%{turn_num => [robot]}`
- [x] Move Parser
- [x] Lobby CRUD
- [x] Handle Move Timeout errors (find a way to test?)
- [x] Break out Game Settings
- [x] Battle Box Game Table (ID, Players, Lobby, Winner, timestamps) Index [(insertedat desc), (gin players), (lobby id)]
- [x] User controller
- [x] Tear out phoenix pubsub for game engine pubsub and use registry
- [x] Sequential turn mode
- [x] players > 2 game mode
- [x] Domain Name
  - [x] pick one
  - [x] www. to github pages
  - [x] Point domain to servers
- [x] Game Live Page
  - [x] Show the (Live) Badge
  - [x] Show if its recorded
  - [x] Reload the page if there is a failure
- [x] Health Check
  - [x] Server Health Check
  - [x] Database Health Check (Through Server)
- [x] BanHammer
  - [x] Be able to stop a banned user from doing things in the platform
  - [x] Banned Users can still sign out, and use the site like a non logged in user
  - [x] Be able to alert a user that they are banned
  - [x] Be able to stop bots from connecting if they belong to a banned user
- [x] Admin
  - [x] List all users (paginated?)
  - [x] Apply a ban to a user
- [x] Change `move` to `command` for refering to what the bot sends to the server
- [x] CSRF protect logout
- [x] url identifiers
   - [x] `/bots/foo`
   - [x] `/lobbies/foo`
   - [x] `/users/grantjamespowell`
   - [x] `/users/grantjamespowell/bots`
   - [x] `/users/grantjamespowell/lobbies`
- [x] deal with invalid moves submission
- [x] Make Github Name not required (github doesn't require it)
- [x] Terrain as binary
- [x] Include the terrain in game settings on startup
- [x] The GameEngine should pass `:timeout` and not `[]` when a player misses a timeout
- [x] Fix the min/max time messages after a game cancel in the bot server
- [x] Phoenix 1.5 upgrade
  - [x] Live dashboard with auth done via `user.is_admin`
  - [x] Basic Telemetry

### Useful SQL

Find number of game bots for a user
```
 select users.github_login_name, count(*) from game_bots join bots on bots.id = game_bots.bot_id join users on users.id = bots.user_id group by users.id order by count desc;
```

Number of bots per user
```
select github_login_name, count(*) from bots join users on bots.user_id = users.id group by users.id order by count desc;
```

Number of lobbies per user
```
select github_login_name, count(*) from lobbies join users on lobbies.user_id = users.id group by users.id order by count desc;
```

Number of games per lobby
```
select lobbies.name, count(*) from games join lobbies on games.lobby_id = lobbies.id group by lobbies.id order by count desc;
```
