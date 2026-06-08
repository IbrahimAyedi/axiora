# Smart Constat Mobile App

Lightweight Flutter mobile foundation for an automotive and insurance inspection product.

## Current scope

- Mobile-only architecture
- Riverpod-ready state management foundation
- GoRouter-ready navigation foundation
- Dio-ready networking foundation
- Feature-first structure with clear `data`, `domain`, and `presentation` separation where needed
- Minimal placeholder screens and services only

## Folder philosophy

- `app/`: application shell, routing, theming, localization, and environment config
- `core/`: reusable cross-feature utilities, network, storage, services, widgets, and error primitives
- `features/`: feature-first modules, expanded into `data`, `domain`, and `presentation` only when the feature warrants it
- `generated/`: reserved for future code generation output

## Recommended dependencies for `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.6.1
  go_router: ^14.8.1
  dio: ^5.9.0
  intl: ^0.20.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

## Suggested next steps

1. Install the recommended dependencies.
2. Add generated localization support if and when copy starts to grow.
3. Wire storage, permissions, camera, notifications, and ML Kit only when those workstreams begin.
4. Keep business logic inside feature modules, not inside `app/` or `core/`.
