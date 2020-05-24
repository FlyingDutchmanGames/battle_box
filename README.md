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

#### Bots
#### Lobbies
- [ ] Robot Game Settings
  - [ ] Terrain Editor
- [ ] bot self play allowed toggle
- [ ] user self play allowed toggle
#### Games
- [ ] Historical Games Filtered/Paginated by [user, bot, lobby]
- [ ] Live Games that meet the same criteria
#### Clients
- [ ] BattleBox Elixir Client
- [ ] BattleBox Python Client
- [ ] Make sure user input can't cause a game to crash
- [ ] WebSocket interface
#### Robot Game Representation
- [ ] limit memory usage of game servers (they're currently at 2 mbs)
- [ ] Manual GC?
#### Static Site
- [ ] Wire protocol docs
- [ ] Robot game rules docs
- [ ] Switch bot tokens to user tokens
#### Robot Game
- [ ] More efficent game visualizer
- [ ] Make the end turns the number of turns in the game
- [ ] Remove row-min/max from terrain, because everything must be 0 indexed
#### General
- Upgrade phoenix/liveview
- Impersonation
- Concurrent connection limiter
- Enforce ASCII < 12 chars no spaces/special in names of everything
  - [ ] User.username
  - [ ] Lobby.name
  - [ ] Bot.name

### Nice to Haves

- [ ] Matchmaker page
- [ ] Handle when connection is closed on trying to send from connection server
- [ ] A decent bot implmentation for testing
- [ ] Connection Debugger (this has some issues due to amount of messages...)
- [ ] Downloads controller, and `as_downloadable` as part of the game protocol
- [ ] Google Analytics on the github page
- [ ] Game Engine Stats Server/Interface (# Live Games, # Most Active Lobby, # Connections)?
- [ ] Build TicTacToe as proof of game engine extendability
- [ ] `mix battle_box.swarm {optional credentials file}` task to run a swarm against a botskrieg server for regression testing
- [ ] Pass timing info to the game so it can do move timing
- [ ] Make all tests async by passing the ecto sandbox to all of the game engine

### Useful SQL

Find number of game bots for a user
```
 select users.user_name, count(*) from game_bots join bots on bots.id = game_bots.bot_id join users on users.id = bots.user_id group by users.id order by count desc;
```

Number of bots per user
```
select user_name, count(*) from bots join users on bots.user_id = users.id group by users.id order by count desc;
```

Number of lobbies per user
```
select user_name, count(*) from lobbies join users on lobbies.user_id = users.id group by users.id order by count desc;
```

Number of games per lobby
```
select lobbies.name, count(*) from games join lobbies on games.lobby_id = lobbies.id group by lobbies.id order by count desc;
```
