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
#### Admin
- Show number of bots/arenas/games by user
#### Users
- provide a way to change username
- provide avatars that are not from github
- Have a way to have users not from github
#### Games
- Historical Games Filtered/Paginated by [user, user + bot]
- Better test the Game controller
#### Clients
- BattleBox Elixir Client
- BattleBox Python Client
- WebSocket interface
- Update protocol to give the result of each move
#### Robot Game
- limit memory usage of game servers (they're currently at 2 mbs)
- Fix terrain to be the right orientation
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
#### Client
- remake protocol from `arena_name` => `arena` `bot_name` => `bot` and make `bot` optional and default to `unnamed`
- have a `use BattleBoxClient.Bot, game_type: RobotGame` macro
  - MyBot.start(arena, opts \\ %{})
    - opts
      - credential: "TOKEN"
      - uri: "battleboxs://botskrieg.com:4242"
  - Choose host / protocol
    `opt passed to start/2` `$BATTLE_BOX_SERVER_URI` `Application.get_env(:battle_box_client, :server_uri)` `battleboxs://botskrieg.com:4242` 
  - implicitly load one of (in order) `opt passed to start/2` `$BATTLE_BOX_CREDENTIALS`, `$BATTLE_BOX_CRENDENTIAL_FILE`, `.battle_box_crendentials` `throw error with helpful info`
    - {"localhost": { "token": "asdbasdafsdfas"}, "botskrieg.com": {"token": "asdasdfas"}} <- creds format
    - Load the credential for the host being connected to
#### General
- Handle when connection is closed on trying to send from connection server
- Api Key -> Key
- Root Api Keys under users
- Login return to
- "Not found" revaamp 
  - perserve bread crumbs

### Nice to Haves

- Impersonation
- Game Engine Stats Server/Interface (# Live Games, # Most Active arena, # Connections)?
- Build TicTacToe/Othello/ as proof of game engine extendability
- Pass timing info to the game so it can do move timing
- Make all tests async by passing the ecto sandbox to all of the game engine
- Rip out webpack/npm? It seems like we could eliminate a pretty huge dep if its basically static css and js
