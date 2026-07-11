# Chatty-Pet Architecture

## Core Rule

Templates define possibility. Runtime state defines current truth. The reducer mutates truth. Events and lines describe confirmed outcomes. UI renders truth and forwards user requests.

## Layers

- `lib/core/`: deterministic models, actions, events, and reducer logic
- `lib/content/`: starter templates and future datapack-style content
- `lib/ui/`: rendering and input surfaces
- `lib/app/`: app shell and state wiring

## v0.1 Scope

The first pass keeps one pet, one room, a tiny invisible grid, a few spawnable items, and reducer-confirmed speech feedback.

## Future Direction

Future narration, save/load, datapacks, creator tools, and Google Play release work all sit on top of the reducer-owned spine instead of bypassing it.
