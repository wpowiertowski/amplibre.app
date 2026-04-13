.PHONY: build test clean hooks

build:
	swift build

test:
	swift build
	swift test

clean:
	rm -rf ~/Library/Developer/Xcode/DerivedData/Amplibre-*
	swift package clean

hooks:
	@echo "Installing git hooks..."
	@cp scripts/pre-commit .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "Done."
