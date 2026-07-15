.PHONY: archive build build-universal clean install release-archive run run-app validate-release

APP_NAME         ?= CCMonitor
BUNDLE           ?= $(APP_NAME).app
NATIVE_BINARY    := .build/release/$(APP_NAME)
UNIVERSAL_BINARY := .build/apple/Products/Release/$(APP_NAME)
INSTALL_DIR      ?= $(HOME)/.local/bin
OUTPUT_DIR       ?= dist
VERSION          ?= 1.0.0
BUILD_NUMBER     ?= 1
ARCHIVE          ?= $(OUTPUT_DIR)/$(APP_NAME)-v$(VERSION)-macos-universal.zip
PLIST_BUDDY      := /usr/libexec/PlistBuddy

# Build release binary and wrap it in a minimal .app bundle.
build:
	swift build -c release
	@rm -rf $(BUNDLE)
	@mkdir -p $(BUNDLE)/Contents/MacOS $(BUNDLE)/Contents/Resources
	@cp $(NATIVE_BINARY) $(BUNDLE)/Contents/MacOS/$(APP_NAME)
	@cp Info.plist $(BUNDLE)/Contents/Info.plist
	@echo "Built $(BUNDLE)"

# Build an arm64 and x86_64 application bundle for GitHub Releases.
build-universal:
	@test "$(VERSION)" != "" && printf '%s' "$(VERSION)" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$$'
	@test "$(BUILD_NUMBER)" != "" && printf '%s' "$(BUILD_NUMBER)" | grep -Eq '^[0-9]+$$'
	swift build -c release --arch arm64 --arch x86_64
	@rm -rf $(BUNDLE)
	@mkdir -p $(BUNDLE)/Contents/MacOS $(BUNDLE)/Contents/Resources
	@cp $(UNIVERSAL_BINARY) $(BUNDLE)/Contents/MacOS/$(APP_NAME)
	@cp Info.plist $(BUNDLE)/Contents/Info.plist
	@$(PLIST_BUDDY) -c "Set :CFBundleShortVersionString $(VERSION)" $(BUNDLE)/Contents/Info.plist
	@$(PLIST_BUDDY) -c "Set :CFBundleVersion $(BUILD_NUMBER)" $(BUNDLE)/Contents/Info.plist
	@echo "Built universal $(BUNDLE) ($(VERSION), build $(BUILD_NUMBER))"

# Archive a previously built bundle for upload to GitHub Releases.
archive:
	@test -d $(BUNDLE)
	@mkdir -p $(OUTPUT_DIR)
	@rm -f $(ARCHIVE)
	ditto -c -k --sequesterRsrc --keepParent $(BUNDLE) $(ARCHIVE)
	@echo "Created $(ARCHIVE)"

release-archive: build-universal archive

# Validate the unsigned release artifact without requiring an Apple Developer account.
validate-release:
	@test -d $(BUNDLE)
	@test -f $(ARCHIVE)
	plutil -lint $(BUNDLE)/Contents/Info.plist
	@test "$$($(PLIST_BUDDY) -c 'Print :CFBundleShortVersionString' $(BUNDLE)/Contents/Info.plist)" = "$(VERSION)"
	@test "$$($(PLIST_BUDDY) -c 'Print :CFBundleVersion' $(BUNDLE)/Contents/Info.plist)" = "$(BUILD_NUMBER)"
	lipo $(BUNDLE)/Contents/MacOS/$(APP_NAME) -verify_arch arm64 x86_64
	unzip -Z1 $(ARCHIVE) | grep -qx '$(APP_NAME).app/Contents/Info.plist'

# Quick dev run via swift run (no .app bundle; Dock icon may flash briefly).
run:
	swift run

# Launch the .app bundle (requires 'make build' first).
run-app: build
	open $(BUNDLE)

# Copy the .app bundle to ~/.local/bin.
install: build
	@mkdir -p $(INSTALL_DIR)
	@rm -rf $(INSTALL_DIR)/$(BUNDLE)
	@cp -r $(BUNDLE) $(INSTALL_DIR)/$(BUNDLE)
	@echo "Installed to $(INSTALL_DIR)/$(BUNDLE)"
	@echo "Launch with: open $(INSTALL_DIR)/$(BUNDLE)"

clean:
	swift package clean
	rm -rf $(BUNDLE) $(OUTPUT_DIR)
