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
- [ ] Upgrade phoenix/liveview

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
- [ ] Make all tests async by passing the ecto sandbox to all of the game engine

### Done
- [x] Have the game table have all the data about the game
- [x] Httpoison => ~Mojito~ Gun

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
