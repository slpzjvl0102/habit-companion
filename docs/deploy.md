# Deploy & Ops

## Live now — PWA (web)
- **URL: https://slpzjvl0102.github.io/habit-companion/**
- Host: GitHub Pages, `gh-pages` branch (root), public repo.
- Install on the 실행자's Android phone: open the URL in Chrome → `⋮` → **"홈 화면에 추가"** → app icon + fullscreen.
- Data is **per-device localStorage** — it lives on whatever phone opened it, and does NOT sync. Run the experiment on ONE device (the 실행자's phone). Opening the URL on the 관리자's own phone shows a separate empty instance.

## Redeploy after code changes (PWA)
One command:
```
powershell -File scripts\deploy.ps1
```
(Rebuilds web with the correct base-href and force-pushes `build/web` to the `gh-pages` branch. Pages rebuilds in ~1 min.)

## Native APK — later (Android Studio)
Only needed if you want a real native app (e.g., reliable evening reminder notifications). The PWA above is enough for the experiment.
1. Install **Android Studio** (~several GB) → installs the Android SDK + platform-tools.
2. Accept licenses: `flutter doctor --android-licenses`
3. Fix the Java 26 ↔ Gradle 9.1 warning by pointing Flutter at Android Studio's bundled JDK:
   `flutter config --jdk-dir="<Android Studio path>/jbr"`
4. Connect the phone (Developer options → USB debugging) or start an emulator.
5. Build/install:
   - `flutter run` — build + install on the connected device, or
   - `flutter build apk` → `build/app/outputs/flutter-apk/app-release.apk` → sideload to the phone.
   - This is a direct sideload, **not** a Play Store release (overkill for an N=1 experiment).

## In-app labels
UI shows **아이 / 부모** (kid-friendly). In docs/discussion these are the **실행자 (executor) / 관리자 (manager)** roles.
