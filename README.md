# World Cup App

World Cup 2026 in your menu bar. Shows live scores while matches are on, fixtures and group tables in a popover, and sends goal notifications.

No API key, no setup — data comes from ESPN's public scoreboard API.

## Build

```sh
make run   # dev
make app   # bundle WorldCupApp.app
```

## Notifications

Goal, kickoff and full-time notifications only work from the bundled app (`make app`) — macOS won't deliver them for a bare `swift run` binary.
