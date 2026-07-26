#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioServices.h>
#import <substrate.h>
#import <dlfcn.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <stdint.h>

typedef void (*NLMPrivateAudioFunction)(
    SystemSoundID,
    uintptr_t,
    uintptr_t,
    uintptr_t,
    uintptr_t,
    uintptr_t,
    uintptr_t,
    uintptr_t
);

typedef OSStatus (*NLMCreateSystemSoundIDFunction)(
    CFURLRef,
    SystemSoundID *
);

typedef OSStatus (*NLMCreateSystemSoundIDWithPathFunction)(
    CFStringRef,
    SystemSoundID *
);

typedef OSStatus (*NLMCreateSystemSoundIDWithOptionsFunction)(
    CFDictionaryRef,
    SystemSoundID *
);

typedef OSStatus (*NLMDisposeSystemSoundIDFunction)(SystemSoundID);

static NLMPrivateAudioFunction gNLMOriginalPlayWithOptions = NULL;
static NLMCreateSystemSoundIDFunction
    gNLMOriginalCreateSystemSoundID = NULL;
static NLMCreateSystemSoundIDWithPathFunction
    gNLMOriginalCreateSystemSoundIDWithPath = NULL;
static NLMCreateSystemSoundIDWithOptionsFunction
    gNLMOriginalCreateSystemSoundIDWithOptions = NULL;
static NLMDisposeSystemSoundIDFunction
    gNLMOriginalDisposeSystemSoundID = NULL;
static NSMutableDictionary<NSNumber *, NSURL *> *gNLMSoundURLs = nil;

@interface NLMPlayerKeeper : NSObject <AVAudioPlayerDelegate>
@property (nonatomic, strong) NSMutableArray<AVAudioPlayer *> *players;
+ (instancetype)sharedKeeper;
- (BOOL)playURL:(NSURL *)URL;
@end

@implementation NLMPlayerKeeper

+ (instancetype)sharedKeeper {
    static NLMPlayerKeeper *keeper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keeper = [NLMPlayerKeeper new];
        keeper.players = [NSMutableArray array];
    });
    return keeper;
}

- (BOOL)playURL:(NSURL *)URL {
    AVAudioSession *session = AVAudioSession.sharedInstance;
    NSError *sessionError = nil;
    if (![session
            setCategory:AVAudioSessionCategoryAmbient
            mode:AVAudioSessionModeDefault
            options:AVAudioSessionCategoryOptionMixWithOthers
            error:&sessionError]) {
        return NO;
    }

    NSError *activeError = nil;
    if (![session setActive:YES error:&activeError]) {
        return NO;
    }

    NSError *playerError = nil;
    AVAudioPlayer *player = [[AVAudioPlayer alloc]
        initWithContentsOfURL:URL
        error:&playerError];
    if (player == nil) {
        return NO;
    }

    player.delegate = self;
    player.volume = 1.0f;
    [player prepareToPlay];

    @synchronized (self) {
        [self.players addObject:player];
    }

    if (![player play]) {
        @synchronized (self) {
            [self.players removeObject:player];
        }
        return NO;
    }

    return YES;
}

- (void)audioPlayerDidFinishPlaying:
    (AVAudioPlayer *)player
    successfully:(BOOL)flag {
    @synchronized (self) {
        [self.players removeObject:player];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:
    (AVAudioPlayer *)player
    error:(NSError *)error {
    @synchronized (self) {
        [self.players removeObject:player];
    }
}

@end

static void NLMRememberSoundURL(
    SystemSoundID soundID,
    NSURL *URL
) {
    if (URL == nil) {
        return;
    }

    @synchronized (gNLMSoundURLs) {
        gNLMSoundURLs[@(soundID)] = [URL copy];
    }
}

static OSStatus NLMCreateSystemSoundID(
    CFURLRef fileURL,
    SystemSoundID *soundID
) {
    OSStatus status =
        gNLMOriginalCreateSystemSoundID(fileURL, soundID);

    if (status == noErr && fileURL != NULL && soundID != NULL) {
        NLMRememberSoundURL(
            *soundID,
            [(__bridge NSURL *)fileURL copy]
        );
    }

    return status;
}

static OSStatus NLMCreateSystemSoundIDWithPath(
    CFStringRef path,
    SystemSoundID *soundID
) {
    OSStatus status =
        gNLMOriginalCreateSystemSoundIDWithPath(path, soundID);

    if (status == noErr && path != NULL && soundID != NULL) {
        NSString *pathString = (__bridge NSString *)path;
        NSURL *URL = pathString.length == 0
            ? nil
            : [NSURL fileURLWithPath:pathString];
        NLMRememberSoundURL(*soundID, URL);
    }

    return status;
}

static NSURL *NLMURLFromCreateOptions(CFDictionaryRef options) {
    if (options == NULL ||
        CFGetTypeID(options) != CFDictionaryGetTypeID()) {
        return nil;
    }

    NSDictionary *dictionary = (__bridge NSDictionary *)options;
    CFStringRef *URLKeyAddress = (CFStringRef *)dlsym(
        RTLD_DEFAULT,
        "kAudioServicesCreateSystemSoundIDOptionAudioFileURLKey"
    );
    id value =
        URLKeyAddress == NULL || *URLKeyAddress == NULL
            ? nil
            : dictionary[(__bridge NSString *)*URLKeyAddress];

    if ([value isKindOfClass:[NSURL class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSString class]]) {
        return [NSURL fileURLWithPath:value];
    }

    for (id candidate in dictionary.allValues) {
        if ([candidate isKindOfClass:[NSURL class]] &&
            [candidate isFileURL]) {
            return candidate;
        }
        if ([candidate isKindOfClass:[NSString class]]) {
            NSString *candidatePath = candidate;
            NSString *extension =
                candidatePath.pathExtension.lowercaseString;
            if ([extension isEqualToString:@"caf"] ||
                [extension isEqualToString:@"wav"] ||
                [extension isEqualToString:@"aif"] ||
                [extension isEqualToString:@"aiff"] ||
                [extension isEqualToString:@"m4r"]) {
                return [NSURL fileURLWithPath:candidatePath];
            }
        }
    }

    return nil;
}

static OSStatus NLMCreateSystemSoundIDWithOptions(
    CFDictionaryRef options,
    SystemSoundID *soundID
) {
    OSStatus status =
        gNLMOriginalCreateSystemSoundIDWithOptions(options, soundID);

    if (status == noErr && soundID != NULL) {
        NLMRememberSoundURL(
            *soundID,
            NLMURLFromCreateOptions(options)
        );
    }

    return status;
}

static OSStatus NLMDisposeSystemSoundID(SystemSoundID soundID) {
    @synchronized (gNLMSoundURLs) {
        [gNLMSoundURLs removeObjectForKey:@(soundID)];
    }
    return gNLMOriginalDisposeSystemSoundID(soundID);
}

static BOOL NLMNotificationOptions(uintptr_t options) {
    if (options < 0x100000000ULL) {
        return NO;
    }

    CFTypeRef object = (CFTypeRef)options;
    if (CFGetTypeID(object) != CFDictionaryGetTypeID()) {
        return NO;
    }

    NSDictionary *dictionary = (__bridge NSDictionary *)object;
    return [
        dictionary[@"PlaySystemSoundOption_Behavior"]
        integerValue
    ] == 1;
}

static BOOL NLMNowPlayingMediaIsActive(void) {
    Class mediaControllerClass = objc_getClass("SBMediaController");
    SEL sharedInstanceSelector = sel_registerName("sharedInstance");
    if (mediaControllerClass != Nil &&
        [mediaControllerClass
            respondsToSelector:sharedInstanceSelector]) {
        id controller =
            ((id (*)(id, SEL))objc_msgSend)(
                (id)mediaControllerClass,
                sharedInstanceSelector
            );
        const char *playingSelectors[] = {
            "isPlaying",
            "nowPlayingAppIsPlaying",
            "isNowPlayingAppPlaying"
        };
        for (NSUInteger index = 0;
             controller != nil &&
             index < sizeof(playingSelectors) /
                sizeof(playingSelectors[0]);
             index++) {
            SEL selector =
                sel_registerName(playingSelectors[index]);
            if ([controller respondsToSelector:selector]) {
                return ((BOOL (*)(id, SEL))objc_msgSend)(
                    controller,
                    selector
                );
            }
        }

        Ivar cachedPlayingIvar = class_getInstanceVariable(
            mediaControllerClass,
            "_lastNowPlayingAppIsPlaying"
        );
        if (controller != nil && cachedPlayingIvar != NULL) {
            ptrdiff_t offset = ivar_getOffset(cachedPlayingIvar);
            const uint8_t *bytes =
                (const uint8_t *)(__bridge const void *)controller;
            return *(const BOOL *)(bytes + offset);
        }
    }

    return AVAudioSession.sharedInstance
        .secondaryAudioShouldBeSilencedHint;
}

static void NLMPlayWithOptions(
    SystemSoundID soundID,
    uintptr_t options,
    uintptr_t arg2,
    uintptr_t arg3,
    uintptr_t arg4,
    uintptr_t arg5,
    uintptr_t arg6,
    uintptr_t arg7
) {
    if (!NLMNotificationOptions(options) ||
        !NLMNowPlayingMediaIsActive()) {
        gNLMOriginalPlayWithOptions(
            soundID, options, arg2, arg3, arg4, arg5, arg6, arg7
        );
        return;
    }

    NSURL *URL = nil;
    @synchronized (gNLMSoundURLs) {
        URL = [gNLMSoundURLs[@(soundID)] copy];
    }

    if (URL == nil ||
        ![[NLMPlayerKeeper sharedKeeper] playURL:URL]) {
        gNLMOriginalPlayWithOptions(
            soundID, options, arg2, arg3, arg4, arg5, arg6, arg7
        );
        return;
    }

    // Successful mixed playback replaces the native call. Calling both paths
    // produces a delayed duplicate notification sound on iOS 16.
}

static BOOL NLMHookFunction(
    const char *symbol,
    void *replacement,
    void **original
) {
    void *address = dlsym(RTLD_DEFAULT, symbol);
    if (address == NULL) {
        return NO;
    }

    MSHookFunction(address, replacement, original);
    return *original != NULL;
}

%ctor {
    @autoreleasepool {
        gNLMSoundURLs = [NSMutableDictionary dictionary];

        NLMHookFunction(
            "AudioServicesCreateSystemSoundID",
            (void *)&NLMCreateSystemSoundID,
            (void **)&gNLMOriginalCreateSystemSoundID
        );
        NLMHookFunction(
            "AudioServicesCreateSystemSoundIDWithPath",
            (void *)&NLMCreateSystemSoundIDWithPath,
            (void **)&gNLMOriginalCreateSystemSoundIDWithPath
        );
        NLMHookFunction(
            "AudioServicesCreateSystemSoundIDWithOptions",
            (void *)&NLMCreateSystemSoundIDWithOptions,
            (void **)&gNLMOriginalCreateSystemSoundIDWithOptions
        );
        NLMHookFunction(
            "AudioServicesDisposeSystemSoundID",
            (void *)&NLMDisposeSystemSoundID,
            (void **)&gNLMOriginalDisposeSystemSoundID
        );
        NLMHookFunction(
            "AudioServicesPlaySystemSoundWithOptions",
            (void *)&NLMPlayWithOptions,
            (void **)&gNLMOriginalPlayWithOptions
        );
    }
}
