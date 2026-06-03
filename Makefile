.PHONY: build run run-app install clean

APP_NAME    = CCMonitor
BUNDLE      = $(APP_NAME).app
BINARY      = .build/release/$(APP_NAME)
INSTALL_DIR = $(HOME)/.local/bin

# Build release binary and wrap it in a minimal .app bundle.
build:
	swift build -c release
	@mkdir -p $(BUNDLE)/Contents/MacOS $(BUNDLE)/Contents/Resources
	@cp $(BINARY) $(BUNDLE)/Contents/MacOS/$(APP_NAME)
	@cp Info.plist $(BUNDLE)/Contents/Info.plist
	@echo "Built $(BUNDLE)"

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
	rm -rf $(BUNDLE)
