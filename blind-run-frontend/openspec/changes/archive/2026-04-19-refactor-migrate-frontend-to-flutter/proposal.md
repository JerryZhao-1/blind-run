# Change: Migrate Frontend to Flutter

## Why
The current project is a React/Vite prototype aimed at demonstrating a dual-role blind runner and volunteer experience. The product now needs a single mobile-first codebase that ships as native Android and iOS apps without depending on a backend.

## What Changes
- Replace the React/Vite app as the primary runtime with a Flutter app targeting Android and iOS.
- Rebuild the existing role selection, blind-side, volunteer-side, and settings flows in Flutter.
- Replace Firebase and browser-only APIs with local mock repositories, device speech services, and local persistence.
- Introduce Flutter routing, state management, shared theme tokens, and reusable mobile UI components.
- Preserve the existing interaction model and visual separation between blind and volunteer experiences.

## Impact
- Affected specs: `flutter-frontend-migration`
- Affected code: root application runtime, navigation, state management, mock data layer, Android/iOS project files
