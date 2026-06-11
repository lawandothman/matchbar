APP = WorldCupApp

run:
	swift run

build:
	swift build -c release

app: build
	rm -rf $(APP).app
	mkdir -p $(APP).app/Contents/MacOS
	cp .build/release/$(APP) $(APP).app/Contents/MacOS/
	cp Resources/Info.plist $(APP).app/Contents/
	codesign --force --sign - $(APP).app

clean:
	rm -rf .build $(APP).app

.PHONY: run build app clean
