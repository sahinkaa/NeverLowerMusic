# NeverLowerMusic16 1.0.0

Initial public release.

## Features

- Prevents notifications from ducking or lowering actively playing media.
- Plays notification and media audio together.
- Uses normal iOS notification playback when media is stopped or paused.
- Ringer volume and Silent Mode work normally when media is not playing.
- Avoids duplicate or echoed notification sounds.
- Contains no diagnostics or analytics.

## Volume behavior

While media is playing, notification volume follows the current media volume.
When media is not playing, notification volume follows the normal ringer
setting.

## Compatibility

- iOS 16.x
- Rootless Dopamine/ElleKit
- Dopamine RootHide after conversion with RootHide Patcher
- arm64 and arm64e

Tested on iPhone 8 Plus, iOS 16.6, Dopamine RootHide.

Inspired by NeverLowerMusic by Rishanan. Coded with OpenAI Codex and tested by
sahinkaa.
