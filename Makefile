.PHONY: build test run ci ci-xcode

build:
	swift build

test:
	swift test

run:
	swift run MacMover

ci: build test ci-xcode

ci-xcode:
	./scripts/xcodebuild-check.sh
