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
#
# CocoaPods output is excluded from the delete pass. It is generated inside the run
# directory and does not exist in this repository, so without these excludes every sync
# would wipe Pods while leaving the Xcode project still referencing them, and the build
# would fail with "Module not found" for whichever plugin Xcode reached first.
mobile-sync:
	@mkdir -p $(MOBILE_RUN_DIR)
	@rsync -a --delete --exclude build --exclude .dart_tool --exclude .idea \
		--exclude ios/Pods --exclude ios/.symlinks --exclude ios/Podfile.lock \
		--exclude macos/Pods --exclude macos/Podfile.lock \
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

## code: print the newest verification code the backend wrote
#
# Only useful while EMAIL_OUTBOX_DIR is set and no SMTP provider is configured, which is
# the state a development machine is in until real mail credentials exist.
code:
	@f=$$(ls -t backend/tmp/mail/*.txt 2>/dev/null | head -1); \
	if [ -z "$$f" ]; then \
		echo "hali hech qanday xabar yozilmagan"; \
	else \
		echo "$$(grep '^To:' $$f)"; \
		echo "kod: $$(awk '/code = /{print $$3; exit}' $$f)"; \
		echo "vaqt: $$(basename $$f | cut -c1-19)"; \
	fi

## e2e: drive the sign-in flows on a simulator against the running backend
#
# Not part of `make test`: it needs a booted simulator, a running backend and a few
# minutes. Run it when the auth screens change.
e2e:
	@./scripts/e2e-mobile.sh

## test: run the backend and mobile suites
test:
	$(MAKE) -C backend test
	cd mobile && flutter test

## lint: analyse every application
lint:
	$(MAKE) -C backend lint
	cd mobile && dart analyze
	cd admin && npx eslint src
