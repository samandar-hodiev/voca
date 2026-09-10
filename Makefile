# Voca — root task entry point.
#
# Delegates to each application rather than duplicating its commands.

MOBILE_RUN_DIR := /tmp/voca-run/mobile

.PHONY: help backend admin mobile mobile-fresh mobile-reset test lint

BUNDLE_ID := com.voca.voca

## help: list targets
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## //'

## backend: run the API on :8082
backend:
	$(MAKE) -C backend run

## admin: run the admin dashboard on :3000
admin:
	cd admin && npm run dev

## mobile-sync: copy the app outside iCloud so iOS can codesign
#
# iOS builds fail when the project sits on the iCloud-synced Desktop: iCloud stamps
# directories with com.apple.FinderInfo and codesign refuses to sign the Flutter
# framework. See docs/runbooks/local-development.md.
#
# Edit code in this repository; this target copies it before each run.
mobile-sync:
	@mkdir -p $(MOBILE_RUN_DIR)
	@rsync -a --delete --exclude build --exclude .dart_tool --exclude .idea \
		mobile/ $(MOBILE_RUN_DIR)/
	@xattr -cr /tmp/voca-run 2>/dev/null || true
	@cd $(MOBILE_RUN_DIR) && flutter pub get >/dev/null

## mobile: sync and run on the first booted simulator
#
# Once running, press R (capital) to hot restart and replay the splash.
# Lowercase r is hot reload, which keeps the current screen.
mobile: mobile-sync
	@cd $(MOBILE_RUN_DIR) && flutter run -d $$(xcrun simctl list devices booted -j \
		| python3 -c "import sys,json; d=json.load(sys.stdin)['devices']; \
print(next(x['udid'] for v in d.values() for x in v))")

## mobile-reset: erase the app from the simulator, so onboarding shows again
#
# Onboarding runs once and the answer is stored on the device. Reinstalling the app does
# NOT clear that: the flag lives in the app's data container, which survives a plain
# install. Erasing the app is what resets it.
mobile-reset:
	@xcrun simctl terminate booted $(BUNDLE_ID) 2>/dev/null || true
	@xcrun simctl uninstall booted $(BUNDLE_ID) 2>/dev/null || true
	@echo "app erased from the booted simulator; the next run starts as a first install"

## mobile-fresh: erase, then run as a brand new install (splash + onboarding)
mobile-fresh: mobile-reset mobile

## gitpulse-hook: install the pre-push hook that notifies GitPulse
#
# Git hooks live in .git/hooks, which is not tracked, so every clone installs its own.
# The hook itself is versioned at scripts/pre-push-hook.sh.
gitpulse-hook:
	@cp scripts/pre-push-hook.sh .git/hooks/pre-push
	@chmod +x .git/hooks/pre-push
	@echo "pre-push hook installed; a successful push now notifies GitPulse"

## test: run the backend and mobile suites
test:
	$(MAKE) -C backend test
	cd mobile && flutter test

## lint: analyse every application
lint:
	$(MAKE) -C backend lint
	cd mobile && dart analyze
	cd admin && npx eslint src
