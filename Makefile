THEOS_PACKAGE_SCHEME ?= rootless
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NeverLowerMusic16

NeverLowerMusic16_FILES = Tweak.xm
NeverLowerMusic16_CFLAGS = -fobjc-arc
NeverLowerMusic16_FRAMEWORKS = Foundation AVFoundation AudioToolbox
NeverLowerMusic16_INSTALL_PATH = /usr/lib/TweakInject

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 mediaserverd 2>/dev/null || true; killall -9 SpringBoard 2>/dev/null || true"
