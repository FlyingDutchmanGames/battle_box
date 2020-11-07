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
- Update protocol to give the result of each move
#### ELO rankings
- Provide optional ELOs to arenas
#### General
- Switch to Tesla instead of hand rolled HTTP client
- Handle when connection is closed on trying to send from connection server
- Api Key -> Key
- Root Api Keys under users
- Login return to
- "Not found" revaamp 
  - preserve bread crumbs
- Tests around rejecting games in the client
- Add a color to the gamebot so the games look different
- Debug Messages in the protocol
- Require clients to connect with `game_type` param, optionally passing a specific arena. (default to the default arena)

### Nice to Haves

- Impersonation
- Game Engine Stats Server/Interface (# Live Games, # Most Active arena, # Connections)?
- Pass timing info to the game so it can do move timing
- Make all tests async by passing the ecto sandbox to all of the game engine
- Rip out webpack/npm? It seems like we could eliminate a pretty huge dep if its basically static css and js
- Admin - Show number of bots/arenas/games by user
- Comprehensive Telemetry Metrics
