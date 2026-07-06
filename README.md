# MacLock

A tiny macOS menu bar timer for focused work sessions.

## Features

- 45-minute work timer
- Menu bar progress indicator
- Break prompt when time is up
- `Day End` state for stopping the loop

## Requirements

- macOS 13+
- Swift 6+

## Run

```sh
./scripts/run.sh
```

## Check

```sh
swift run MacLockCheck
```

## Package

```sh
./scripts/package.sh
open .build/MacLock.app
```

## Structure

```text
Sources/MacLock       macOS app
Sources/MacLockCore   timer state logic
Sources/MacLockCheck  lightweight checks
scripts/              run and package helpers
```
