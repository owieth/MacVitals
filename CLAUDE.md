# MacVitals

macOS menu bar app for monitoring system vitals (CPU, Memory, Storage, Battery, Thermals).

## Tech Stack

- Swift 6, SwiftUI, macOS 15+
- Xcode project (not SPM-based app target)
- No SPM dependencies for MVP
- Non-sandboxed (needed for SMC/process enumeration)

## Architecture

- MVVM with @Observable ViewModel annotated @MainActor
- Singleton services: SystemMonitor (timer orchestrator), collectors (CPU, Memory, Storage, Battery, Thermal, Process)
- UserPreferences: @MainActor ObservableObject singleton using UserDefaults
- Menu bar app via NSPopover (AppDelegate manages status item)
- WindowManager handles settings window
- Launch at login via SMAppService (native macOS 13+)

## Project Structure

```
MacVitals/MacVitals/          # Source root
  Models/                     # Data models (CPUInfo, MemoryInfo, etc.)
  Services/                   # System data collectors + orchestrator
  ViewModels/                 # @Observable view models
  Views/                      # SwiftUI views (popover, sections, settings)
  Utilities/                  # Preferences, formatters, constants
MacVitals/MacVitalsTests/     # Unit tests
```

## Conventions

- Conventional commits: type(scope): subject
- English only for code, comments, docs
- Use `rg` not `grep`, `fd` not `find`
- Self-documenting code over comments

## Build

```sh
xcodebuild -project MacVitals/MacVitals.xcodeproj -scheme MacVitals -configuration Debug build
```

## Test

```sh
xcodebuild -project MacVitals/MacVitals.xcodeproj -scheme MacVitals -configuration Debug test
```
