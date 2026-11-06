# Never Lower Music

Keep music and other media at their current volume when a notification sound plays.

## Compatibility

Installable on iOS 16.0 and later. Separate packages are available for rootless and RootHide jailbreaks with a Substrate-compatible tweak injector.

- iPhone 8 Plus on iOS 16.6 with Dopamine RootHide, tested with the earlier converted package.
- iPhone 11 Pro Max on iOS 26.0.1 with Dopamine 3 RootHide, tested with the native build.

## Notification volume

While media is playing, notification sounds follow the media volume instead of the ringer volume. When media is paused or stopped, iOS handles notification sounds with its usual ringer and Silent Mode behavior. The tweak also falls back to iOS playback if mixed playback cannot start.

## Installation

1. Add [sahinkaa](https://sahinkaa.github.io/) to Sileo or Zebra and install **Never Lower Music**. You can also download the matching package from [GitHub Releases](https://github.com/sahinkaa/NeverLowerMusic/releases).
2. Choose `iphoneos-arm64` for rootless or `iphoneos-arm64e` for RootHide when installing a downloaded package. The RootHide package installs directly.
3. Restart userspace to reload SpringBoard and the audio services.

Existing NeverLowerMusic16 installs can upgrade in place, including packages converted with RootHide Patcher. The package identifier is `com.sahinkaa.neverlowermusic16`.

## Building

Use [Theos](https://theos.dev/) with an iOS SDK and the RootHide package scheme for the native RootHide build.

```sh
export THEOS=/path/to/theos
make clean package THEOS_PACKAGE_SCHEME=rootless FINALPACKAGE=1
make clean package THEOS_PACKAGE_SCHEME=roothide FINALPACKAGE=1
```

The packages are written to `packages/`.

## Credits

The idea comes from the original **NeverLowerMusic** tweak by **Rishanan**. This implementation was built with Codex and tested by sahinkaa.

Released under the [MIT License](LICENSE).
