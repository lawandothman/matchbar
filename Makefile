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
	mkdir -p $(APP).app/Contents/MacOS $(APP).app/Contents/Resources $(APP).app/Contents/Frameworks
	cp .build/release/$(APP) $(APP).app/Contents/MacOS/
	cp Resources/Info.plist $(APP).app/Contents/
	cp Resources/AppIcon.icns $(APP).app/Contents/Resources/
	cp -R "$$(find .build/artifacts -type d -name Sparkle.framework -path '*macos*' | head -1)" $(APP).app/Contents/Frameworks/
	codesign --force --deep --sign - $(APP).app

release: app
	codesign --force --options runtime --deep --sign "$(IDENTITY)" $(APP).app/Contents/Frameworks/Sparkle.framework
	codesign --force --options runtime --sign "$(IDENTITY)" $(APP).app
	rm -rf dist $(APP).dmg
	mkdir dist
	cp -R $(APP).app dist/
	ln -s /Applications dist/Applications
	hdiutil create -volname "World Cup App" -srcfolder dist -ov -format UDZO $(APP).dmg
	rm -rf dist
	xcrun notarytool submit $(APP).dmg --keychain-profile $(PROFILE) --wait
	xcrun stapler staple $(APP).dmg
	@echo "$(APP).dmg is notarized and ready to distribute"

clean:
	rm -rf .build dist $(APP).app $(APP).dmg

.PHONY: run build icon app release clean
