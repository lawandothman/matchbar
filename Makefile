APP = WorldCupApp
IDENTITY ?= Developer ID Application
PROFILE ?= worldcup-notary

run:
	swift run

build:
	swift build -c release

icon:
	swift scripts/make-icon.swift

app: build
	rm -rf $(APP).app
	mkdir -p $(APP).app/Contents/MacOS $(APP).app/Contents/Resources
	cp .build/release/$(APP) $(APP).app/Contents/MacOS/
	cp Resources/Info.plist $(APP).app/Contents/
	cp Resources/AppIcon.icns $(APP).app/Contents/Resources/
	codesign --force --sign - $(APP).app

release: app
	codesign --force --options runtime --sign "$(IDENTITY)" $(APP).app
	ditto -c -k --keepParent $(APP).app $(APP).zip
	xcrun notarytool submit $(APP).zip --keychain-profile $(PROFILE) --wait
	xcrun stapler staple $(APP).app
	ditto -c -k --keepParent $(APP).app $(APP).zip
	@echo "$(APP).zip is notarized and ready to distribute"

clean:
	rm -rf .build $(APP).app $(APP).zip

.PHONY: run build icon app release clean
