.PHONY: test build app build-universal dmg clean

SWIFT_ENV = env CLANG_MODULE_CACHE_PATH=.build/module-cache
SWIFT_SCRATCH = --scratch-path .build/scratch

test:
	$(SWIFT_ENV) swift run $(SWIFT_SCRATCH) TickeysCoreTestRunner

build:
	$(SWIFT_ENV) swift build $(SWIFT_SCRATCH) --product Tickeys-Swift

app:
	$(SWIFT_ENV) bash scripts/build-app.sh

build-universal:
	$(SWIFT_ENV) UNIVERSAL=1 bash scripts/build-app.sh

# Create a compressed DMG containing the built app bundle.
# Requires macOS `hdiutil`.
dmg:
	$(SWIFT_ENV) bash scripts/build-dmg.sh

clean:
	rm -rf .build/app .build/dmg
