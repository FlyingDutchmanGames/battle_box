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
- add in server ais
- Matchmaker queue live
- set of default arenas with interesting terrains and bots
#### Users
- provide a way to change username
- provide avatars that are not from github
- Have a way to have users not from github
#### Clients
- BattleBox Elixir Client
- BattleBox Python Client
- WebSocket interface
- Update protocol to give the result of each move
#### Robot Game
- Fix the weird rendering thing, where attacks and moves are no in the right place
- Move rules into main robot game docs
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
#### Static Site
- Dynamically created docs
- Wire protocol docs
- Robot game rules docs
#### ELO rankings
- Provide optional ELOs to arenas
#### General
- Move arena specificer into `practice` and `match_maker`
- Handle when connection is closed on trying to send from connection server
- Api Key -> Key
- Root Api Keys under users
- Login return to
- "Not found" revaamp 
  - preserve bread crumbs
- Clean up matchspecs with Ex2Ms
- Tests around rejecting games in the client
- Add a color to the gamebot so the games look different
#### Client
- Add specs to the python client
  - Provide an API key for a banned user
  - Provide an api key for a user with a 0 connection limit
  - Enforce that `not-real-arena` can never be made into an arena to give a fake arena for testing
  - Create an arena with a 0 time ms so test failed move timings?

### Nice to Haves

- Impersonation
- Game Engine Stats Server/Interface (# Live Games, # Most Active arena, # Connections)?
- Build TicTacToe/Othello/ as proof of game engine extendability
- Pass timing info to the game so it can do move timing
- Make all tests async by passing the ecto sandbox to all of the game engine
- Rip out webpack/npm? It seems like we could eliminate a pretty huge dep if its basically static css and js
- Admin - Show number of bots/arenas/games by user
- Comprehensive Telemetry Metrics
