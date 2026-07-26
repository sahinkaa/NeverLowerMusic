# NeverLowerMusic16

NeverLowerMusic16 prevents notification sounds from lowering or ducking
now-playing audio on iOS 16.

## Volume behavior

- **While media is playing:** the notification and media play together without
  ducking. Notification loudness follows the current **media volume**, not the
  separate ringer-volume setting.
- **While media is stopped or paused:** the normal iOS notification path is
  used. Notification loudness follows **ringer volume**, and Silent Mode works
  normally.

## How it works

The tweak records the sound file associated with each notification
system-sound ID. While media is playing, it replays that file through a mixed
ambient audio session and suppresses the original system-sound call. This
prevents iOS from reducing the volume of the playing media and avoids a
duplicate or echoed notification.

If media is not playing, or if mixed playback cannot start, the tweak leaves
notification playback to iOS.

## Compatibility

- iOS 16.x
- Rootless jailbreaks with a Substrate-compatible injector
- Dopamine with ElleKit
- arm64 and arm64e

Tested on an iPhone 8 Plus running iOS 16.6 with Dopamine RootHide after
converting the package with RootHide Patcher.

RootHide users must convert the release package with RootHide Patcher before
installation.

## Installation

1. Download the `.deb` from the GitHub Releases page.
2. RootHide users: convert it with RootHide Patcher.
3. Install it using Sileo, Zebra, or another package manager.
4. Restart SpringBoard or reboot userspace.

Remove packages with the old experimental identifier
`com.codex.neverlowermusic16` before installing.

## Building

Install [Theos](https://theos.dev/) with an iOS SDK, then run:

```sh
export THEOS=/path/to/theos
make clean package FINALPACKAGE=1
```

The rootless package will be created inside `packages/`.

## Credits and authorship

Inspired by the original **NeverLowerMusic** tweak by **Rishanan**.

This project was coded with **OpenAI Codex** and tested by **sahinkaa**.
sahinkaa is not a developer and does not claim to have written the code
manually.

## Redistribution

The project is released under the MIT License. Anyone may host it on a
jailbreak repository, build it, modify it, and redistribute it in accordance
with the license.
