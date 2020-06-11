# Botskrieg Documentation

## What is Botskrieg?

Botskrieg is a platform for building, debugging, and fighting bots against other users in real time.

Botskrieg is written in [Elixir](https://elixir-lang.org/) on top of the `BattleBox` multiplayer game engine.

## Getting Started

## Games

### Robot Game

## Why build this?

Botskrieg is the classroom assignment I always wanted when I was learning to program. My goal with Botskrieg is to give programming teachers a tool to build classroom assignments around.

## What is BattleBox?

BattleBox is the Multiplayer Game Engine I wrote to support Botskrieg.

The goals of BattleBox are as follows

1.) Allow for ten thousand simultaneous games on a single commodity cloud server
2.) Allow for realtime\* interaction between humans and games
3.) Make it easy to add new game types and leverage existing runtime BattleBox components for new games. (I.E. I should never have to write another matchmaker or lobby system)
4.) Be open source so that people can build their own games for personal use, and potentially contribute them back to the upstream

## What other games are coming down the pipe?

My next game I'm working on is Texas Hold'em. I like it because it's different from robot game in the following ways

1.) Variable number of players (2-6)
2.) Secret information (player hands)
3.) Sequential as opposed to simultaneous turns
4.) It would be fun for a human to play against a bot, so it makes sense to build a Human(s) v Bot(s) mode.

I also like it for the following reasons

1.) Computers haven't mastered it. Games like connect four or tic-tac-toe wouldn't be fun on Botskrieg because you could write an AI that plays perfectly
2.) There is an element of randomness
3.) Most people know how to play it, and there is a large real life following

## You should build Game `SGAME`.

You should build game `$GAME`!

BattleBox is designed to be extensible. I'm keeping the source code private as of now while I work out the performance and learn a few lessons from running it in production and I build poker so make sure that other types of games make sense with the abstractions I've provided.

The long term goal of BattleBox is to be released open source. Looking back at when I first learned to code, this is _*EXACTLY*_ the thing I wanted when I was first learning.

## Why is BattleBox written in Elixir?

I'm a full time Elixir developer! Elixir is really good at soft realtime concurrent applications.

\* Soft Realtime... Like in the Erlang sense of the word, and not in like the scientific hard realtime sense
