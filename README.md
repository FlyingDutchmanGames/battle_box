# BattleBox

## The OpenSource Bot Battle Platform

## SETUP

0.) Setup a postgres database according to `dev.exs`
1.) Get your credentials in github and make a `dev.secret.exs` based on `dev.secret.exs.example` 
  * Use `http://localhost:4000/auth/github/callback` as your callback url
2.) `mix deps.get && mix ecto.setup`

## TODO

### V1

#### Arenas
- Matchmaker queue live
- Move Arena Live into its own page instead of the main arena page
- Add "Auto Follow Arena" when you click on a live game from the arena's live game page
- set of default arenas with interesting terrains and bots
#### Users
- provide a way to change username
- provide avatars that are not from github
- Have a way to have users not from github
#### Clients
- BattleBox Elixir Client
- BattleBox Python Client
- BattleBox Node Client
- BattleBox Ruby Client
- WebSocket interface
- Update protocol to give the result of each move
#### Robot Game
- Remove `new` in favor of `from_settings`
- limit memory usage of game servers (they're currently at 2 mbs)
- Manual GC?
- Robot game give out random player ids / color coding based on player 
- Make sure user input can't cause a game to crash (maybe changesets)
- Procedural terrain generation?
- Area conquer mode
- Robot Game Settings
  - Reorgainze the code
  - Add in team spawns
#### Docs
- Robot game rules docs
#### ELO rankings
- Provide optional ELOs to arenas
#### General
- Handle when connection is closed on trying to send from connection server
- Api Key -> Key
- Root Api Keys under users
- Login return to
- "Not found" revaamp 
  - preserve bread crumbs
- Tests around rejecting games in the client
- Add a color to the gamebot so the games look different
- Add matchmaker interface to the game engine

### Nice to Haves

- Impersonation
- Game Engine Stats Server/Interface (# Live Games, # Most Active arena, # Connections)?
- Build TicTacToe/Othello/ as proof of game engine extendability
- Pass timing info to the game so it can do move timing
- Make all tests async by passing the ecto sandbox to all of the game engine
- Rip out webpack/npm? It seems like we could eliminate a pretty huge dep if its basically static css and js
- Admin - Show number of bots/arenas/games by user
- Comprehensive Telemetry Metrics
