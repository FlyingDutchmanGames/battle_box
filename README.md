# BattleBox

## Hitlist

[ ] Make the `Game.robots` function more efficent by denormalizing a `game.robots_at_turn` to be a `%{turn_num => [robot]}`
[ ] A decent bot implmentation for testing
[ ] historical games page
[ ] live games page
[ ] Bot Info Page
[ ] Game Engine Stats Server (# Live Games, # Most Active Lobby, # Connections)?
[ ] Tear out phoenix pubsub for game engine pubsub and use registry
[ ] Remove GenStateMachine in favor of built in :genstatem
[ ] bot self play/user self play lobby matchmaker settings
[ ] Github Pages landing page
[ ] Pick a domain name and associate it
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
