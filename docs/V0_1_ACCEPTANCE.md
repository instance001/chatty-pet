# V0.1 Acceptance

## Core Toy

- app launches
- splash screen transitions into the toy screen
- pet stage is visible
- starter items can be spawned
- stage items can be selected from the stage or item strip
- pet can tick and move without leaving bounds
- idle pet can wander when there are no active targets
- inspect works on a valid nearby item
- edible items can be consumed
- toy items remain after play
- impossible actions reject honestly with visible feedback

## Support Surface

- in-app `Help` explains the basic loop
- in-app `Privacy` explains the local-first posture
- in-app `About` shows app identity and license information

## Engineering

- `flutter analyze` passes
- `flutter test` passes
- `flutter build appbundle` succeeds
