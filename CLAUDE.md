# CHIP8AR

iOS AR frontend for the CHIP-8 emulator.

## Build

```bash
xcodebuild clean build -project CHIP8AR/CHIP8AR.xcodeproj -scheme CHIP8AR \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=NO
```

Note: the xcodeproj is nested one level deep (`CHIP8AR/CHIP8AR.xcodeproj`).

## Architecture

Xcode project consuming `Chip8EmulatorPackage` via SPM. The dependency version is pinned in `CHIP8AR/CHIP8AR.xcodeproj/project.pbxproj`.

Source is in `CHIP8AR/CHIP8AR/`:

- **ViewController** — main view controller, implements `Chip8EngineDelegate`, ARKit scene
- **Chip8View** — UIView subclass for rendering pixels
- **TouchInputCode / TouchInputMappingService** — maps touch input to `Chip8InputCode`
- **PlatformSupportedRomService** — platform ROM selection

## Dependency Updates

When `Chip8EmulatorPackage` is tagged with a new version:
1. Update the version in `CHIP8AR/CHIP8AR.xcodeproj/project.pbxproj`
2. Delete `CHIP8AR/CHIP8AR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
3. Build to verify

## Workflow

- Branch protection on `main`: PR required, `build` CI check required, enforce admins
- CI: `.github/workflows/build.yml` — xcodebuild on macOS

### PR flow

1. Commit to a feature branch
2. Push and create PR
3. Set PR to auto-merge (`gh pr merge --auto --squash`)
4. CI must pass before merge completes
