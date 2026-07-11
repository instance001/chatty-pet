# Play Store Metadata Draft

## App Identity

- App name: `Chatty Pet`
- Package ID: `io.instance001.chattypet`
- Steward: `Fractal Media Infrastructure (FMI)`
- Category suggestion: `Casual`
- Type: `Game`
- Pricing: `Free`
- Ads: `No`

## Short Description

Tiny local-first pet care game where Chatty notices items, moves around, and reacts.

## Full Description

Chatty Pet is a small local-first care toy built around a tiny living pet named Chatty.

Place snacks, toys, cozy items, and tidy-up tools on the stage. Tap an item to select it, guide Chatty over, and watch little reactions play out in the activity box. Good care helps Chatty stay fed, playful, rested, tidy, and cheerful.

This first release is focused on a simple, readable care loop:

- place items on the map
- tap a map item to select it
- scoot Chatty over
- inspect or use the selected item
- unlock more shelf items through affection and care

Chatty Pet is designed to stay honest about what it is:

- local-first play
- no account required
- no ads
- no in-app purchases
- save data stays on the device

The app is built around a deterministic reducer-owned world state, which means the game responds consistently to the actions you take. The result is a tiny pet terrarium that feels playful, understandable, and easy to revisit for short cozy check-ins.

If you enjoy small pet games, tidy toy-like interactions, and simple care loops without account pressure or monetization clutter, Chatty Pet is made for that kind of play.

## Release Notes Draft

### `en-AU`

First public Android release of Chatty Pet.

- local-first pet care gameplay
- compact landscape layout for mobile play
- item placement, selection, scoot, inspect, and use actions
- in-app help, privacy, and about panels
- custom item creation

## Screenshot Shot List

Capture these from the Android build on-device if possible:

1. Main compact landscape play view with map, activity box, and right utility rail visible
2. Chatty reacting to a selected item in the activity box
3. Care shelf with several unlocked item groups visible
4. Make Item panel open with readable controls
5. Help panel open

## Console Declarations Notes

- Ads: `No`
- Account creation: `No`
- In-app purchases: `No`
- Social features: `No`
- Core experience works offline after install: `Yes`
- Save data: local on device

## Data Safety Starting Point

This is not legal advice, but based on the current app behavior in this repo:

- Personal data collected: likely `No`
- Data shared with third parties: likely `No`
- Account creation required: `No`
- Advertising ID used: likely `No`
- Purchases handled: `No`
- Gameplay save data stored locally on device: `Yes`

Confirm these in Play Console against the final shipped build before submitting.
