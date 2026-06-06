# BeanBook for Android — v1 Core Logging MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship an installable native Android BeanBook (Kotlin + Jetpack Compose + Room) that covers spec §10: create/edit/pin bags, log a brew through the 3-step flow (cold and hot start), view brew list and detail, re-brew from prefill, save a recipe, and switch themes — all persisted locally across launches.

**Architecture:** A new, fully independent Android project at `/Users/marcus/Developer/BeanBook-Android` (own git history). Room mirrors the SwiftData schema `[Bag, Brew, BrewPreset]`; thin repositories mirror the iOS stores (including the dormant Pro-quota seam); a `ViewModel`+`StateFlow` layer drives Compose screens; theming is a custom palette system over a Material3 substrate, light-locked. The iOS app is the behavioral spec — every contract in this plan cites the iOS source file it ports.

**Tech Stack:** Kotlin (AGP 9 built-in), Jetpack Compose (BOM 2026.05.01), Room 2.8.4 + KSP, DataStore Preferences, Navigation-Compose, manual DI (`AppContainer`). No Hilt, no network, no Firebase.

**Spec:** [`docs/superpowers/specs/2026-06-06-android-port-design.md`](../../specs/2026-06-06-android-port-design.md) (in the **iOS** repo — this plan also lives there; only the plan checkboxes change in the iOS repo during execution).

---

## Read this first — repo split

- **This plan file** lives in the iOS repo (`BeanBook`, branch `claude/recursing-bardeen-dcab01`). Tick checkboxes here.
- **Every implementation file** goes to `/Users/marcus/Developer/BeanBook-Android` — a NEW directory and NEW git repository created in Task 1. Never add Android code to the iOS repo or its worktrees.
- All `git` commands in Tasks 1–26 run inside `/Users/marcus/Developer/BeanBook-Android` unless stated otherwise.
- iOS source paths cited as contracts (e.g. `BeanBook/Features/Brews/NewBrewSheet.swift`) are relative to the iOS repo. **Read the cited iOS file before building each screen** — it is the fidelity source for copy, spacing, and behavior.
- `docs/branding.md` and `docs/design.md` (iOS repo) are cross-platform law. All user-facing copy is ported **verbatim** from the iOS views.

## Verified toolchain (do not re-derive)

Everything below was **verified empirically on this machine on 2026-06-06** with a throwaway walking skeleton (`assembleDebug` green; APK launched and observed on the emulator via screenshot; `testDebugUnitTest` green; `connectedDebugAndroidTest` ran a Room in-memory DAO test on the emulator, green). Treat these pins as fact; if you change one, re-verify the whole ladder before proceeding.

| Component | Version | Empirical notes |
|---|---|---|
| Gradle (wrapper) | **9.5.1** | Wrapper jar copied from `/Users/marcus/Developer/BookMark/BOOKMARK-Android` (no global `gradle` on this machine), `distributionUrl` bumped to 9.5.1 |
| JDK | **Android Studio JBR 21** | Pinned via `org.gradle.java.home=/Applications/Android Studio.app/Contents/jbr/Contents/Home` in `gradle.properties`. System `java` is Oracle 22 — do **not** rely on it |
| AGP | **9.2.1** | AGP 9 has **built-in Kotlin**: applying `org.jetbrains.kotlin.android` is an **error** ("no longer required since AGP 9.0"). Apply only `com.android.application`, `org.jetbrains.kotlin.plugin.compose`, `com.google.devtools.ksp` |
| Kotlin compose plugin | **2.3.21** | Verified compatible with AGP 9.2.1's embedded Kotlin |
| KSP | **2.3.9** | Standalone versioning (no longer `<kotlin>-x.y.z`) |
| Room | **2.8.4** | KSP processing verified (`kspDebugKotlin` ran) |
| Compose BOM | **2026.05.01** | |
| compileSdk | **37** | `core-ktx 1.19.0` requires AGP ≥ 9.1.0 **and** compileSdk 37. Platform 37 was auto-installed by the build (licenses already accepted). `minSdk 26`, `targetSdk 36` per spec |
| core-ktx / activity-compose / nav-compose / lifecycle / datastore | 1.19.0 / 1.13.0 / 2.9.8 / 2.10.0 / 1.2.1 | Latest stable from Google Maven, resolved 2026-06-06 |
| androidx.test ext-junit / runner | 1.3.0 / 1.7.0 | Instrumented harness verified |

**Emulator:** the only AVD is **`Medium_Phone_API_36.1`** (API 36.1). `adb` is NOT on PATH — use `~/Library/Android/sdk/platform-tools/adb`.

```bash
# Boot (once per session); ~30–60 s to full boot
nohup ~/Library/Android/sdk/emulator/emulator -avd Medium_Phone_API_36.1 \
  -no-snapshot-save -no-audio -no-boot-anim > /tmp/emulator.log 2>&1 &
~/Library/Android/sdk/platform-tools/adb wait-for-device
~/Library/Android/sdk/platform-tools/adb shell 'while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 1; done; echo BOOTED'
```

## Verification ladder (per task)

1. **Compile gate:** `./gradlew :app:assembleDebug` → `BUILD SUCCESSFUL`.
2. **JVM test gate:** `./gradlew :app:testDebugUnitTest` → `BUILD SUCCESSFUL`.
3. **Instrumented gate** (emulator running): `./gradlew :app:connectedDebugAndroidTest` → `BUILD SUCCESSFUL`.
4. **Observation gate** (UI tasks): install, launch, screenshot, and **look at it**:
   ```bash
   ./gradlew :app:installDebug
   ~/Library/Android/sdk/platform-tools/adb shell am start -n com.beanbook.app/.MainActivity
   sleep 3 && ~/Library/Android/sdk/platform-tools/adb exec-out screencap -p > /tmp/bb-task-N.png
   ```
   A UI task is not done until the screenshot shows the contracted behavior. Never assert success from code inspection (house rule).

Commit after every green task (conventional commits). Never `--no-verify`.

## Decisions & deviations from spec (deliberate, not gaps)

1. **`waterTempC` (spec §5 says "decide and note in the plan"):** exact iOS parity. iOS persists `waterTempC`, hydrates it from method defaults (`defaultWaterTempC`) and prefill, and **exposes no input control** in the brew flow; it only displays in `BrewDetailView` ("Water · 94°C"). Android v1 does the same: column + hydration + detail display, no Shot-step control. This *is* the iOS behavior, so parity is exact, and the column is live (not silently dropped).
2. **Full Bag schema.** Spec §4 under-enumerates `Bag`. The iOS model (`BeanBook/Core/Models/Bag.swift`) has `brand`, `name`, `roastLevel`, `origin`, `process?`, `tastingNotes: [String]`, `roastedOn?`, `purchasedAt?`, `imageData?`, `notes?`, `createdAt`, `isPinned`. The spec names the iOS app the behavioral spec, so the Room schema mirrors the **full** model. `imageData` columns (Bag and Brew) ship nullable with no capture UI (spec already defers brew photos; bag photos defer with them).
3. **Onboarding deferred.** Spec §5's screen list has no onboarding; the `hasOnboarded` DataStore key is reserved (written nowhere in v1) so a Phase-4 onboarding needs no migration. App launches straight into the root scaffold.
4. **Brew-list search + filter chips deferred.** iOS `BrewListView` today has search and method/bag filter chips; spec §5 deliberately scopes the v1 brew list to: chronological list, `RecentShotsStrip`, saved-recipes entry, long-press "Brew again". Search/filters go in `parity.md` as Phase-4 polish.
5. **`prefillPreset` path omitted from the v1 ViewModel.** Spec §5: "RecipesView launch deferred with the Recipes screen." The only preset surface in v1 is the save-as-recipe toggle. YAGNI; the hydration ladder documents where the preset branch slots in for Phase 4.
6. **All 11 palettes selectable in v1** (no Pro tier exists yet — spec §5 puts themes in, Pro out). ⚠️ Phase-2 must decide whether early Android users keep Pro palettes (grandfather) before billing ships; recorded in `parity.md`. `Palette.isPro` is carried as data now.
7. **Plan granularity:** complete code for the foundation (build files, schema, repositories, theme data, NewBrew ViewModel + tests) where correctness is subtle; behavioral contracts + key snippets for screens, citing the iOS source file as the fidelity reference. House precedent: `docs/superpowers/plans/completed/2026-05-29-motion-cohesion-pass.md`.
8. **Units row ports as stored-but-cosmetic.** iOS `preferredUnit` ("g"/"oz") is stored and surfaced in Settings but consumed nowhere. Port identically (parity over logic invention).
9. **SF Symbols → Material Symbols mapping** (iOS rule is SF-only; Android analog is Material-only): espresso→`LocalCafe`, pourOver→`WaterDrop`, frenchPress→`Coffee`, aeroPress→`FilterAlt`, mokaPot→`LocalFireDepartment`, coldBrew→`AcUnit`, pin→`PushPin`, brew-again→`Refresh`, add→`Add`, settings→`Settings`. Approximations are acceptable; consistency is the rule.
10. **iOS sheet presentations → Android:** NewBrew opens as a **full-screen dialog** (no back-stack entry, mirrors iOS modal sheet; system Back = Cancel). BrewList/Settings/PalettePicker are nav destinations with Back (Android idiom for iOS's "Done"-dismissed sheets).
11. **Serif display type = `FontFamily.Serif`** (system serif). Bundling a custom serif is a Phase-4 polish item in `parity.md`.

## Milestones

| Milestone | Tasks | Exit criterion |
|---|---|---|
| **M1 Foundation + data layer** | 1–6 | Walking skeleton on emulator; schema, repos, settings all green under instrumented tests — self-contained, UI-free |
| **M2 Theme + primitives** | 7–9 | All 11 palettes + shared editorial components render in a debug gallery screen |
| **M3 App shell** | 10 | Bottom bar navigation + center "+" opens an (empty) NewBrew dialog |
| **M4 Screens** | 11–17 | Beans/Today/BrewList/BrewDetail/Settings functional with real data |
| **M5 NewBrew flow** | 18–23 | 3-step flow, cold/hot start, Δ-captions, timer, save + save-as-recipe |
| **M6 Acceptance** | 24–26 | Compose UI tests green; parity doc; spec-§10 walkthrough observed on emulator |

## File structure

```
BeanBook-Android/
├── gradlew, gradlew.bat, gradle/wrapper/            # copied from BookMark, distributionUrl → 9.5.1
├── settings.gradle.kts, build.gradle.kts, gradle.properties, local.properties (untracked)
├── gradle/libs.versions.toml
├── docs/parity.md                                   # Task 25
├── README.md
└── app/
    ├── build.gradle.kts
    ├── schemas/                                     # Room exported schemas (checked in)
    └── src/
        ├── main/AndroidManifest.xml
        ├── main/java/com/beanbook/app/
        │   ├── BeanBookApplication.kt               # owns AppContainer
        │   ├── MainActivity.kt                      # theme wiring + RootScaffold
        │   ├── di/AppContainer.kt                   # manual DI
        │   ├── data/db/BeanBookDatabase.kt          # Room DB, version 1
        │   ├── data/db/Converters.kt                # enums, List<String>
        │   ├── data/db/entities/{BagEntity,BrewEntity,BrewPresetEntity}.kt
        │   ├── data/db/daos/{BagDao,BrewDao,BrewPresetDao}.kt
        │   ├── data/repo/{QuotaPolicy,BagRepository,BrewRepository,BrewPresetRepository}.kt
        │   ├── data/settings/SettingsRepository.kt  # DataStore
        │   ├── domain/{BrewMethod,RoastLevel,ProcessMethod}.kt
        │   ├── domain/BrewMath.kt                   # ratio + formatters (computed, not stored)
        │   ├── ui/theme/{Palette,Theme,Motion}.kt
        │   ├── ui/components/{Eyebrow,HairRule,Pills,DeltaCaption,StepperRow,
        │   │                  BigRatio,RatingDots,StarRating,RuleRow}.kt
        │   ├── ui/navigation/RootScaffold.kt
        │   ├── ui/today/TodayScreen.kt
        │   ├── ui/bags/{BagListScreen,BagDetailScreen,BagEditSheet}.kt
        │   ├── ui/brews/{BrewListScreen,BrewDetailScreen,RecentShotsStrip}.kt
        │   ├── ui/newbrew/{NewBrewViewModel,NewBrewSheet,ContextStep,ShotStep,
        │   │               OutcomeStep,BrewTimer,MethodPicker}.kt
        │   └── ui/settings/{SettingsScreen,PalettePickerScreen}.kt
        ├── test/java/com/beanbook/app/              # JVM: domain, formatters, ViewModel
        └── androidTest/java/com/beanbook/app/       # instrumented: DAOs, repos, Compose UI
```

---

# M1 — Foundation + data layer

### Task 1: Scaffold + walking skeleton + git init

**Files:** all build files below, `app/src/main/AndroidManifest.xml`, `app/src/main/java/com/beanbook/app/MainActivity.kt` (placeholder).

These exact files were build-verified on 2026-06-06 (see "Verified toolchain"). Reproduce them verbatim.

- [x] **Step 1: Create the project directory and copy the Gradle wrapper**

```bash
mkdir -p /Users/marcus/Developer/BeanBook-Android/gradle
cd /Users/marcus/Developer/BeanBook-Android
cp /Users/marcus/Developer/BookMark/BOOKMARK-Android/gradlew .
cp -R /Users/marcus/Developer/BookMark/BOOKMARK-Android/gradle/wrapper gradle/wrapper
chmod +x gradlew
sed -i '' 's|gradle-9.0-milestone-1-bin.zip|gradle-9.5.1-bin.zip|' gradle/wrapper/gradle-wrapper.properties
```

- [x] **Step 2: Write the root build files**

`settings.gradle.kts`:
```kotlin
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "BeanBook"
include(":app")
```

`build.gradle.kts` (root — note: **no** `kotlin-android` plugin anywhere; AGP 9 built-in Kotlin):
```kotlin
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.compose) apply false
    alias(libs.plugins.ksp) apply false
}
```

`gradle.properties`:
```properties
android.useAndroidX=true
kotlin.code.style=official
org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configuration-cache=true
android.nonTransitiveRClass=true
org.gradle.java.home=/Applications/Android Studio.app/Contents/jbr/Contents/Home
```

(⚠️ Deliberate bootstrap wart: `org.gradle.java.home` hardcodes this machine's JBR path **and gets committed**. Correct and verified for local v1 development; migrate to a Gradle Java toolchain declaration before adding CI or other contributors.)

`local.properties` (NOT committed):
```properties
sdk.dir=/Users/marcus/Library/Android/sdk
```

`gradle/libs.versions.toml`:
```toml
[versions]
agp = "9.2.1"
kotlin = "2.3.21"
ksp = "2.3.9"
coreKtx = "1.19.0"
activityCompose = "1.13.0"
lifecycle = "2.10.0"
composeBom = "2026.05.01"
navigationCompose = "2.9.8"
datastore = "1.2.1"
room = "2.8.4"
junit = "4.13.2"
androidxTestJunit = "1.3.0"
androidxTestRunner = "1.7.0"
coroutinesTest = "1.10.2"

[libraries]
androidx-core-ktx = { group = "androidx.core", name = "core-ktx", version.ref = "coreKtx" }
androidx-activity-compose = { group = "androidx.activity", name = "activity-compose", version.ref = "activityCompose" }
androidx-lifecycle-viewmodel-compose = { group = "androidx.lifecycle", name = "lifecycle-viewmodel-compose", version.ref = "lifecycle" }
androidx-lifecycle-runtime-compose = { group = "androidx.lifecycle", name = "lifecycle-runtime-compose", version.ref = "lifecycle" }
androidx-compose-bom = { group = "androidx.compose", name = "compose-bom", version.ref = "composeBom" }
androidx-compose-ui = { group = "androidx.compose.ui", name = "ui" }
androidx-compose-material3 = { group = "androidx.compose.material3", name = "material3" }
androidx-compose-material-icons-extended = { group = "androidx.compose.material", name = "material-icons-extended" }
androidx-compose-ui-tooling-preview = { group = "androidx.compose.ui", name = "ui-tooling-preview" }
androidx-compose-ui-tooling = { group = "androidx.compose.ui", name = "ui-tooling" }
androidx-compose-ui-test-junit4 = { group = "androidx.compose.ui", name = "ui-test-junit4" }
androidx-compose-ui-test-manifest = { group = "androidx.compose.ui", name = "ui-test-manifest" }
androidx-navigation-compose = { group = "androidx.navigation", name = "navigation-compose", version.ref = "navigationCompose" }
androidx-datastore-preferences = { group = "androidx.datastore", name = "datastore-preferences", version.ref = "datastore" }
androidx-room-runtime = { group = "androidx.room", name = "room-runtime", version.ref = "room" }
androidx-room-ktx = { group = "androidx.room", name = "room-ktx", version.ref = "room" }
androidx-room-compiler = { group = "androidx.room", name = "room-compiler", version.ref = "room" }
androidx-room-testing = { group = "androidx.room", name = "room-testing", version.ref = "room" }
junit = { group = "junit", name = "junit", version.ref = "junit" }
androidx-test-junit = { group = "androidx.test.ext", name = "junit", version.ref = "androidxTestJunit" }
androidx-test-runner = { group = "androidx.test", name = "runner", version.ref = "androidxTestRunner" }
kotlinx-coroutines-test = { group = "org.jetbrains.kotlinx", name = "kotlinx-coroutines-test", version.ref = "coroutinesTest" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
kotlin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
ksp = { id = "com.google.devtools.ksp", version.ref = "ksp" }
```

(One addition over the verified skeleton: `material-icons-extended`, needed from M2 on. If it fails to resolve under the BOM, pin its last published version — it was deprecated upstream; fallback is inlining the ~10 needed `ImageVector`s.)

- [x] **Step 3: Write the app module**

`app/build.gradle.kts`:
```kotlin
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.ksp)
}

android {
    namespace = "com.beanbook.app"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.beanbook.app"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

ksp {
    arg("room.schemaLocation", "$projectDir/schemas")
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.material.icons.extended)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.navigation.compose)
    implementation(libs.androidx.datastore.preferences)
    implementation(libs.androidx.room.runtime)
    implementation(libs.androidx.room.ktx)
    ksp(libs.androidx.room.compiler)

    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)

    androidTestImplementation(libs.androidx.test.junit)
    androidTestImplementation(libs.androidx.test.runner)
    androidTestImplementation(libs.androidx.room.testing)
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)

    debugImplementation(libs.androidx.compose.ui.tooling)
    debugImplementation(libs.androidx.compose.ui.test.manifest)
}
```

`app/src/main/AndroidManifest.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <application
        android:label="BeanBook"
        android:supportsRtl="true"
        android:theme="@android:style/Theme.Material.Light.NoActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
```

(`BeanBookApplication` arrives in Task 6 — until then `android:name` stays **out** of the manifest, exactly as above; Task 6 adds it. Adding it early compiles fine but crashes at launch with `ClassNotFoundException`.)

`app/src/main/java/com/beanbook/app/MainActivity.kt` (placeholder, replaced in M3):
```kotlin
package com.beanbook.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.material3.Text
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            Text(
                text = "BeanBook walking skeleton",
                modifier = Modifier
                    .fillMaxSize()
                    .wrapContentSize(Alignment.Center)
            )
        }
    }
}
```

- [x] **Step 4: Build**

Run: `cd /Users/marcus/Developer/BeanBook-Android && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL` (first run downloads Gradle 9.5.1 + deps; platform 37 auto-installs if missing).

- [x] **Step 5: Launch on the emulator and observe**

Boot the AVD (see "Verified toolchain"), then:
```bash
./gradlew :app:installDebug
~/Library/Android/sdk/platform-tools/adb shell am start -n com.beanbook.app/.MainActivity
sleep 3 && ~/Library/Android/sdk/platform-tools/adb exec-out screencap -p > /tmp/bb-task-1.png
```
Expected: screenshot shows "BeanBook walking skeleton" centered. **Look at the screenshot.**

- [x] **Step 6: git init + first commit**

```bash
cd /Users/marcus/Developer/BeanBook-Android
git init -b main
printf '%s\n' '.gradle/' 'build/' 'app/build/' 'local.properties' '.DS_Store' '*.hprof' '.kotlin/' > .gitignore
git add -A && git commit -m "feat: walking skeleton — verified toolchain (AGP 9.2.1, Kotlin compose 2.3.21, KSP 2.3.9, Room 2.8.4, compileSdk 37)"
```

---

### Task 2: Domain enums + formatters (pure Kotlin, TDD on JVM)

**Files:**
- Create: `app/src/main/java/com/beanbook/app/domain/BrewMethod.kt`, `RoastLevel.kt`, `ProcessMethod.kt`, `BrewMath.kt`
- Test: `app/src/test/java/com/beanbook/app/domain/BrewMethodTest.kt`, `BrewMathTest.kt`

Ports `BeanBook/Core/Models/BrewMethod.swift`, `RoastLevel.swift`, and the computed members of `Brew.swift`. **Raw values must match iOS exactly** (they are the stored strings — cross-platform data vocabulary).

- [x] **Step 1: Write the failing tests**

`BrewMethodTest.kt` — assert the full defaults table:

| raw | display | dose | yield | time s | tempC | doseRange | yieldRange | yieldLabel | timeLabel |
|---|---|---|---|---|---|---|---|---|---|
| `espresso` | Espresso | 18 | 36 | 30 | null | 12..25 | 20..80 | Yield (g) | Brew time |
| `pourOver` | Pour Over | 22 | 350 | 210 | 94 | 10..60 | 100..700 | Water (g) | Brew time |
| `frenchPress` | French Press | 30 | 500 | 240 | 96 | 20..80 | 200..1000 | Water (g) | Brew time |
| `aeroPress` | AeroPress | 15 | 240 | 90 | 85 | 10..30 | 80..400 | Water (g) | Brew time |
| `mokaPot` | Moka Pot | 18 | 80 | 300 | null | 10..30 | 40..200 | Yield (g) | Brew time |
| `coldBrew` | Cold Brew | 80 | 800 | 43200 | null | 40..200 | 300..2000 | Water (g) | Steep time |

`BrewMathTest.kt` — port of `Brew.swift` computed members + `NewBrewSheet.format`:
- `ratio(dose=18, yield=36) == 2.0`; `ratio(dose=0, …) == 0.0`
- `formattedRatio(2.0) == "1:2.00"`; `formattedRatio(0.0) == "—"` (always 2 fraction digits, mirrors iOS `.fractionLength(2)`)
- `formattedTime(30) == "30s"`, `formattedTime(90) == "1:30"`, `formattedTime(210) == "3:30"`, `formattedTime(43200) == "12:00"` (≥1 h → H:MM, mirrors iOS `.hourMinute`)
- `formatGrams(18.0) == "18"`, `formatGrams(18.5) == "18.5"` (trailing .0 trimmed, else 1 decimal)

- [x] **Step 2: Run, verify FAIL** — `./gradlew :app:testDebugUnitTest` → compilation error (types don't exist).

- [x] **Step 3: Implement**

`BrewMethod.kt`:
```kotlin
package com.beanbook.app.domain

enum class BrewMethod(val raw: String) {
    ESPRESSO("espresso"),
    POUR_OVER("pourOver"),
    FRENCH_PRESS("frenchPress"),
    AERO_PRESS("aeroPress"),
    MOKA_POT("mokaPot"),
    COLD_BREW("coldBrew");

    val displayName: String get() = when (this) {
        ESPRESSO -> "Espresso"; POUR_OVER -> "Pour Over"; FRENCH_PRESS -> "French Press"
        AERO_PRESS -> "AeroPress"; MOKA_POT -> "Moka Pot"; COLD_BREW -> "Cold Brew"
    }
    val defaultDose: Double get() = when (this) {
        ESPRESSO -> 18.0; POUR_OVER -> 22.0; FRENCH_PRESS -> 30.0
        AERO_PRESS -> 15.0; MOKA_POT -> 18.0; COLD_BREW -> 80.0
    }
    val defaultYield: Double get() = when (this) {
        ESPRESSO -> 36.0; POUR_OVER -> 350.0; FRENCH_PRESS -> 500.0
        AERO_PRESS -> 240.0; MOKA_POT -> 80.0; COLD_BREW -> 800.0
    }
    val defaultTimeSeconds: Int get() = when (this) {
        ESPRESSO -> 30; POUR_OVER -> 210; FRENCH_PRESS -> 240
        AERO_PRESS -> 90; MOKA_POT -> 300; COLD_BREW -> 12 * 3600
    }
    /** °C, or null where temperature doesn't apply (boiler/stovetop/cold). */
    val defaultWaterTempC: Double? get() = when (this) {
        POUR_OVER -> 94.0; FRENCH_PRESS -> 96.0; AERO_PRESS -> 85.0
        ESPRESSO, MOKA_POT, COLD_BREW -> null
    }
    val doseRange: ClosedFloatingPointRange<Double> get() = when (this) {
        ESPRESSO -> 12.0..25.0; POUR_OVER -> 10.0..60.0; FRENCH_PRESS -> 20.0..80.0
        AERO_PRESS -> 10.0..30.0; MOKA_POT -> 10.0..30.0; COLD_BREW -> 40.0..200.0
    }
    val yieldRange: ClosedFloatingPointRange<Double> get() = when (this) {
        ESPRESSO -> 20.0..80.0; POUR_OVER -> 100.0..700.0; FRENCH_PRESS -> 200.0..1000.0
        AERO_PRESS -> 80.0..400.0; MOKA_POT -> 40.0..200.0; COLD_BREW -> 300.0..2000.0
    }
    /** Espresso/moka measure liquid OUT; the rest water IN. */
    val yieldLabel: String get() = when (this) {
        ESPRESSO, MOKA_POT -> "Yield (g)"; else -> "Water (g)"
    }
    val doseLabel: String get() = "Dose (g)"
    val timeLabel: String get() = if (this == COLD_BREW) "Steep time" else "Brew time"

    companion object {
        fun fromRaw(raw: String): BrewMethod = entries.firstOrNull { it.raw == raw } ?: ESPRESSO
    }
}
```

`RoastLevel.kt` / `ProcessMethod.kt` (same file pattern; swatch colors live in the theme layer, M2):
```kotlin
package com.beanbook.app.domain

enum class RoastLevel(val raw: String) {
    LIGHT("light"), MEDIUM_LIGHT("mediumLight"), MEDIUM("medium"),
    MEDIUM_DARK("mediumDark"), DARK("dark");

    val displayName: String get() = when (this) {
        LIGHT -> "Light"; MEDIUM_LIGHT -> "Medium-Light"; MEDIUM -> "Medium"
        MEDIUM_DARK -> "Medium-Dark"; DARK -> "Dark"
    }
    companion object { fun fromRaw(raw: String) = entries.firstOrNull { it.raw == raw } ?: MEDIUM }
}

enum class ProcessMethod(val raw: String) {
    WASHED("washed"), NATURAL("natural"), HONEY("honey"),
    ANAEROBIC("anaerobic"), DECAF("decaf"), OTHER("other");

    val displayName: String get() = when (this) {
        WASHED -> "Washed"; NATURAL -> "Natural"; HONEY -> "Honey"
        ANAEROBIC -> "Anaerobic"; DECAF -> "Decaf"; OTHER -> "Other"
    }
    companion object { fun fromRaw(raw: String) = entries.firstOrNull { it.raw == raw } }
}
```

`BrewMath.kt`:
```kotlin
package com.beanbook.app.domain

import java.util.Locale

object BrewMath {
    fun ratio(doseGrams: Double, yieldGrams: Double): Double =
        if (doseGrams > 0) yieldGrams / doseGrams else 0.0

    /** "1:2.00" — always two fraction digits; "—" when ratio is 0. */
    fun formattedRatio(ratio: Double): String =
        if (ratio > 0) "1:" + String.format(Locale.US, "%.2f", ratio) else "—"

    /** <60 s → "30s"; <1 h → "3:30"; ≥1 h → "12:00" (H:MM). */
    fun formattedTime(seconds: Int): String = when {
        seconds < 60 -> "${seconds}s"
        seconds < 3600 -> String.format(Locale.US, "%d:%02d", seconds / 60, seconds % 60)
        else -> String.format(Locale.US, "%d:%02d", seconds / 3600, (seconds % 3600) / 60)
    }

    /** "18" for whole grams, "18.5" otherwise (one decimal). */
    fun formatGrams(value: Double): String =
        if (value % 1.0 == 0.0) value.toInt().toString()
        else String.format(Locale.US, "%.1f", value)
}
```

- [x] **Step 4: Run, verify PASS** — `./gradlew :app:testDebugUnitTest` → `BUILD SUCCESSFUL`.
- [x] **Step 5: Commit** — `git add -A && git commit -m "feat(domain): port BrewMethod/RoastLevel/ProcessMethod enums and brew formatters with tests"`

---

### Task 3: Room schema — entities, converters, database, DAOs (instrumented TDD)

**Files:**
- Create: `data/db/entities/BagEntity.kt`, `BrewEntity.kt`, `BrewPresetEntity.kt`; `data/db/Converters.kt`; `data/db/BeanBookDatabase.kt`; `data/db/daos/BagDao.kt`, `BrewDao.kt`, `BrewPresetDao.kt`
- Test: `app/src/androidTest/java/com/beanbook/app/data/DaoTest.kt`

Mirrors `Bag.swift`/`Brew.swift`/`BrewPreset.swift`. **Every column has a default** (iOS invariant, spec §4). Enum raws stored as iOS strings. `#Index<Brew>([\.createdAt])` → Room `Index`. `@Relationship(deleteRule: .nullify)` → FK `onDelete = SET_NULL`.

- [x] **Step 1: Write the failing instrumented tests** (`DaoTest.kt`, in-memory DB, pattern as in the verified skeleton: `Room.inMemoryDatabaseBuilder` + `runTest`):
  - `bagDefaults_matchIOSSchema` — `BagEntity(id="x")` round-trips with brand `""`, roastLevel `MEDIUM`, tastingNotes `[]`, isPinned `false`, process/roastedOn/purchasedAt/imageData/notes all null.
  - `brewOrderedByCreatedAtDesc` — insert 3 brews (createdAt 1,3,2) → `observeAll().first()` returns 3,2,1.
  - `mostRecent_returnsNewest` — returns createdAt=3 row; `mostRecent_onEmpty_returnsNull`.
  - `deletingBag_nullifiesBrewBagId` — insert bag + brew(bagId=bag.id); delete bag; brew's `bagId == null` and brew still exists (the iOS `.nullify` rule; iOS BagDetail copy promises "Brews on this bag will keep their settings but lose the bag link.").
  - `tastingNotes_roundTrip` — `listOf("cherry", "cocoa")` survives.
  - `presetRoundTrip` — BrewPreset stores no rating/notes/image (compile-time: the entity simply has no such columns).
  - `upsertingExistingBag_doesNotOrphanBrews` — upsert bag, attach brew, upsert same bag with a new name → brew's `bagId` survives (regression guard for the REPLACE/SET_NULL interaction).

- [x] **Step 2: Run, verify FAIL** — emulator up, `./gradlew :app:connectedDebugAndroidTest` → compile failure.

- [x] **Step 3: Implement**

`Converters.kt`:
```kotlin
package com.beanbook.app.data.db

import androidx.room.TypeConverter
import com.beanbook.app.domain.BrewMethod
import com.beanbook.app.domain.ProcessMethod
import com.beanbook.app.domain.RoastLevel

class Converters {
    @TypeConverter fun brewMethodToRaw(m: BrewMethod): String = m.raw
    @TypeConverter fun rawToBrewMethod(raw: String): BrewMethod = BrewMethod.fromRaw(raw)
    @TypeConverter fun roastLevelToRaw(r: RoastLevel): String = r.raw
    @TypeConverter fun rawToRoastLevel(raw: String): RoastLevel = RoastLevel.fromRaw(raw)
    @TypeConverter fun processToRaw(p: ProcessMethod?): String? = p?.raw
    @TypeConverter fun rawToProcess(raw: String?): ProcessMethod? = raw?.let { ProcessMethod.fromRaw(it) }

    // List<String> via unit-separator join; tasting notes never contain \u001F.
    @TypeConverter fun stringListToRaw(list: List<String>): String = list.joinToString("\u001F")
    @TypeConverter fun rawToStringList(raw: String): List<String> =
        if (raw.isEmpty()) emptyList() else raw.split("\u001F")
}
```

`BagEntity.kt`:
```kotlin
package com.beanbook.app.data.db.entities

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.beanbook.app.domain.ProcessMethod
import com.beanbook.app.domain.RoastLevel
import java.util.UUID

@Entity(tableName = "bags", indices = [Index("createdAt")])
data class BagEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val brand: String = "",
    val name: String = "",
    val roastLevel: RoastLevel = RoastLevel.MEDIUM,
    val origin: String = "",
    val process: ProcessMethod? = null,
    val tastingNotes: List<String> = emptyList(),
    val roastedOn: Long? = null,        // epoch millis
    val purchasedAt: Long? = null,
    val imageData: ByteArray? = null,   // column ships in v1; capture UI deferred
    val notes: String? = null,
    val createdAt: Long = System.currentTimeMillis(),
    val isPinned: Boolean = false,
) {
    /** Port of Bag.displayTitle. */
    val displayTitle: String get() = when {
        name.isNotEmpty() && brand.isNotEmpty() -> "$brand — $name"
        brand.isNotEmpty() -> brand
        name.isNotEmpty() -> name
        else -> "Untitled bag"
    }
}
```
(Data-class `ByteArray` equality warnings are acceptable here — identity equality is never relied on; suppress if the build flags it.)

`BrewEntity.kt`:
```kotlin
package com.beanbook.app.data.db.entities

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import com.beanbook.app.domain.BrewMath
import com.beanbook.app.domain.BrewMethod
import java.util.UUID

@Entity(
    tableName = "brews",
    indices = [Index("createdAt"), Index("bagId")],
    foreignKeys = [ForeignKey(
        entity = BagEntity::class,
        parentColumns = ["id"],
        childColumns = ["bagId"],
        onDelete = ForeignKey.SET_NULL
    )]
)
data class BrewEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val method: BrewMethod = BrewMethod.ESPRESSO,
    val doseGrams: Double = 0.0,
    val yieldGrams: Double = 0.0,
    val brewTimeSeconds: Int = 0,
    val grindSetting: String? = null,
    val waterTempC: Double? = null,
    val rating: Int? = null,
    val notes: String? = null,
    val imageData: ByteArray? = null,
    val bagId: String? = null,
    val createdAt: Long = System.currentTimeMillis(),
) {
    val ratio: Double get() = BrewMath.ratio(doseGrams, yieldGrams)
    val formattedRatio: String get() = BrewMath.formattedRatio(ratio)
    val formattedTime: String get() = BrewMath.formattedTime(brewTimeSeconds)
}
```

`BrewPresetEntity.kt`:
```kotlin
package com.beanbook.app.data.db.entities

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.beanbook.app.domain.BrewMethod
import java.util.UUID

/** A target recipe, not a logged shot — no rating, notes, or image (iOS parity). */
@Entity(tableName = "brew_presets")
data class BrewPresetEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String = "",
    val method: BrewMethod = BrewMethod.ESPRESSO,
    val doseGrams: Double = 0.0,
    val yieldGrams: Double = 0.0,
    val brewTimeSeconds: Int = 0,
    val grindSetting: String? = null,
    val waterTempC: Double? = null,
    val createdAt: Long = System.currentTimeMillis(),
)
```

DAOs (Flow reads for UI, suspend writes; `@Upsert` doubles as update — NEVER `@Insert(onConflict = REPLACE)` on the FK parent: SQLite REPLACE = DELETE+INSERT, which fires `ON DELETE SET_NULL` and orphans a bag's brews on every edit):
```kotlin
package com.beanbook.app.data.db.daos

import androidx.room.*
import com.beanbook.app.data.db.entities.BagEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface BagDao {
    @Query("SELECT * FROM bags ORDER BY createdAt DESC") fun observeAll(): Flow<List<BagEntity>>
    @Query("SELECT * FROM bags WHERE id = :id") fun observeById(id: String): Flow<BagEntity?>
    @Query("SELECT * FROM bags WHERE id = :id") suspend fun byId(id: String): BagEntity?
    @Query("SELECT * FROM bags WHERE isPinned = 1 LIMIT 1") suspend fun pinned(): BagEntity?
    @Query("SELECT * FROM bags WHERE isPinned = 1 LIMIT 1") fun observePinned(): Flow<BagEntity?>
    @Query("SELECT COUNT(*) FROM bags") suspend fun count(): Int
    @Upsert suspend fun upsert(bag: BagEntity)
    @Delete suspend fun delete(bag: BagEntity)
    @Query("UPDATE bags SET isPinned = 0") suspend fun clearPins()
    @Query("UPDATE bags SET isPinned = :pinned WHERE id = :id") suspend fun setPinned(id: String, pinned: Boolean)

    /** Single-pin invariant: at most one pinned row, enforced atomically. */
    @Transaction
    suspend fun pinExclusive(id: String, pinned: Boolean) {
        clearPins()
        if (pinned) setPinned(id, true)
    }
}

@Dao
interface BrewDao {
    @Query("SELECT * FROM brews ORDER BY createdAt DESC") fun observeAll(): Flow<List<BrewEntity>>
    @Query("SELECT * FROM brews WHERE bagId = :bagId ORDER BY createdAt DESC")
    fun observeForBag(bagId: String): Flow<List<BrewEntity>>
    @Query("SELECT * FROM brews WHERE id = :id") fun observeById(id: String): Flow<BrewEntity?>
    @Query("SELECT * FROM brews WHERE id = :id") suspend fun byId(id: String): BrewEntity?
    @Query("SELECT * FROM brews ORDER BY createdAt DESC LIMIT 1") suspend fun mostRecent(): BrewEntity?
    @Query("SELECT COUNT(*) FROM brews") suspend fun count(): Int
    @Upsert suspend fun upsert(brew: BrewEntity)
    @Delete suspend fun delete(brew: BrewEntity)
}

@Dao
interface BrewPresetDao {
    @Query("SELECT * FROM brew_presets ORDER BY createdAt DESC") fun observeAll(): Flow<List<BrewPresetEntity>>
    @Query("SELECT COUNT(*) FROM brew_presets") suspend fun count(): Int
    @Upsert suspend fun upsert(preset: BrewPresetEntity)
    @Delete suspend fun delete(preset: BrewPresetEntity)
}
```
(Adjust imports per file; `BrewDao`/`BrewPresetDao` in their own files.)

`BeanBookDatabase.kt`:
```kotlin
package com.beanbook.app.data.db

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.beanbook.app.data.db.daos.BagDao
import com.beanbook.app.data.db.daos.BrewDao
import com.beanbook.app.data.db.daos.BrewPresetDao
import com.beanbook.app.data.db.entities.BagEntity
import com.beanbook.app.data.db.entities.BrewEntity
import com.beanbook.app.data.db.entities.BrewPresetEntity

@Database(
    entities = [BagEntity::class, BrewEntity::class, BrewPresetEntity::class],
    version = 1,
    exportSchema = true
)
@TypeConverters(Converters::class)
abstract class BeanBookDatabase : RoomDatabase() {
    abstract fun bagDao(): BagDao
    abstract fun brewDao(): BrewDao
    abstract fun brewPresetDao(): BrewPresetDao
}
```

- [x] **Step 4: Run, verify PASS** — `./gradlew :app:connectedDebugAndroidTest` → `BUILD SUCCESSFUL`. Confirm `app/schemas/com.beanbook.app.data.db.BeanBookDatabase/1.json` was generated.
- [x] **Step 5: Commit** — `git add -A && git commit -m "feat(data): Room schema mirroring iOS SwiftData models, with instrumented DAO tests"`

---

### Task 4: Repositories + quota seam (instrumented TDD for the pin invariant)

**Files:**
- Create: `data/repo/QuotaPolicy.kt`, `BagRepository.kt`, `BrewRepository.kt`, `BrewPresetRepository.kt`
- Test: `app/src/androidTest/java/com/beanbook/app/data/RepositoryTest.kt`

Analog of `BagStore.swift`/`BrewStore.swift`/`BrewPresetStore.swift`. Quota enforcement exists but is **dormant** (spec §4: "the seam exists so Phase 2 adds enforcement without re-plumbing").

- [x] **Step 1: Write the failing tests** (`RepositoryTest.kt`):
  - `pin_unpinsAllOthers` — create A, B; pin A; pin B → only B pinned.
  - `pin_samebagTwice_unpins` — pin A; pin A again → nothing pinned (iOS toggle semantics: "Pass the same bag again to unpin").
  - `create_persistsAndReturnsEntity` — for all three repos.
  - `quota_denied_throwsQuotaExceeded` — construct `BagRepository` with a `QuotaPolicy { _, _ -> false }` → `create` throws `QuotaExceededException` AND the row is not persisted (assert byId returns null); with the default `UnlimitedQuotaPolicy` it doesn't throw.
  - `pin_unpinsAllOthers` must leave A pinned when B is toggled (do NOT unpin A first — otherwise the clearPins-others path is never exercised).

- [x] **Step 2: Run, verify FAIL.**

- [x] **Step 3: Implement**

`QuotaPolicy.kt`:
```kotlin
package com.beanbook.app.data.repo

enum class QuotaFeature { BAG, BREW, RECIPE }

/** Phase-2 Play Billing plugs in here; v1 ships unlimited. */
fun interface QuotaPolicy {
    fun canCreate(feature: QuotaFeature, currentCount: Int): Boolean
}

object UnlimitedQuotaPolicy : QuotaPolicy {
    override fun canCreate(feature: QuotaFeature, currentCount: Int) = true
}

class QuotaExceededException(val feature: QuotaFeature) :
    Exception("Quota exceeded for $feature")
```

`BagRepository.kt`:
```kotlin
package com.beanbook.app.data.repo

import com.beanbook.app.data.db.daos.BagDao
import com.beanbook.app.data.db.entities.BagEntity
import kotlinx.coroutines.flow.Flow

class BagRepository(
    private val dao: BagDao,
    private val quota: QuotaPolicy,
) {
    val bags: Flow<List<BagEntity>> = dao.observeAll()
    val pinnedBag: Flow<BagEntity?> = dao.observePinned()

    fun observeById(id: String): Flow<BagEntity?> = dao.observeById(id)
    suspend fun byId(id: String): BagEntity? = dao.byId(id)
    suspend fun pinned(): BagEntity? = dao.pinned()

    suspend fun create(bag: BagEntity): BagEntity {
        if (!quota.canCreate(QuotaFeature.BAG, dao.count())) throw QuotaExceededException(QuotaFeature.BAG)
        dao.upsert(bag)
        return bag
    }

    suspend fun update(bag: BagEntity) = dao.upsert(bag)
    suspend fun delete(bag: BagEntity) = dao.delete(bag)

    /** Port of BagStore.pin(_:): pin this bag, unpinning all others; same bag again unpins. */
    suspend fun togglePin(bag: BagEntity) = dao.pinExclusive(bag.id, pinned = !bag.isPinned)
}
```

`BrewRepository.kt` / `BrewPresetRepository.kt` follow the same shape: `brews`/`presets` Flow, `observeForBag`, `create` (quota-checked, `QuotaFeature.BREW`/`RECIPE`), an explicit `update(...) = dao.upsert(...)` (edit paths must NOT route through quota-checked `create`), `delete`, and `suspend fun mostRecent(): BrewEntity?` on BrewRepository (port of `BrewStore.mostRecent()`, used for prefill hydration). `BrewPresetDao` also needs a `byId(id)` query (used by quota non-persistence tests).

- [x] **Step 4: Run, verify PASS** — `./gradlew :app:connectedDebugAndroidTest`.
- [x] **Step 5: Commit** — `git commit -am "feat(data): repositories with single-pin invariant and dormant quota seam"`

---

### Task 5: SettingsRepository (DataStore)

**Files:**
- Create: `data/settings/SettingsRepository.kt`
- Test: `app/src/androidTest/java/com/beanbook/app/data/SettingsRepositoryTest.kt`

Maps the iOS `@AppStorage` keys (spec §3). **Key strings match iOS names.**

- [x] **Step 1: Failing test** — defaults are `paletteId="forest"`, `autoPrefillFromLast=true`, `timerCountsDown=true`, `defaultBrewMethod="espresso"`, `preferredUnit="g"`, `hasOnboarded=false`; a write round-trips.
- [x] **Step 2: Run, verify FAIL.**
- [x] **Step 3: Implement**

```kotlin
package com.beanbook.app.data.settings

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

data class Settings(
    val paletteId: String = "forest",
    val autoPrefillFromLast: Boolean = true,
    val timerCountsDown: Boolean = true,
    val defaultBrewMethod: String = "espresso",
    val preferredUnit: String = "g",       // stored, not yet consumed (iOS parity)
    val hasOnboarded: Boolean = false,     // reserved; unused in v1
)

class SettingsRepository(private val dataStore: DataStore<Preferences>) {
    private object Keys {
        val paletteId = stringPreferencesKey("paletteID")
        val autoPrefill = booleanPreferencesKey("autoPrefillFromLast")
        val timerCountsDown = booleanPreferencesKey("timerCountsDown")
        val defaultBrewMethod = stringPreferencesKey("defaultBrewMethod")
        val preferredUnit = stringPreferencesKey("preferredUnit")
        val hasOnboarded = booleanPreferencesKey("hasOnboarded")
    }

    val settings: Flow<Settings> = dataStore.data.map { p ->
        Settings(
            paletteId = p[Keys.paletteId] ?: "forest",
            autoPrefillFromLast = p[Keys.autoPrefill] ?: true,
            timerCountsDown = p[Keys.timerCountsDown] ?: true,
            defaultBrewMethod = p[Keys.defaultBrewMethod] ?: "espresso",
            preferredUnit = p[Keys.preferredUnit] ?: "g",
            hasOnboarded = p[Keys.hasOnboarded] ?: false,
        )
    }

    suspend fun setPaletteId(v: String) = dataStore.edit { it[Keys.paletteId] = v }
    suspend fun setAutoPrefillFromLast(v: Boolean) = dataStore.edit { it[Keys.autoPrefill] = v }
    suspend fun setTimerCountsDown(v: Boolean) = dataStore.edit { it[Keys.timerCountsDown] = v }
    suspend fun setDefaultBrewMethod(v: String) = dataStore.edit { it[Keys.defaultBrewMethod] = v }
    suspend fun setPreferredUnit(v: String) = dataStore.edit { it[Keys.preferredUnit] = v }
}
```

- [x] **Step 4: Run, verify PASS.**  - [ ] **Step 5: Commit** — `git commit -am "feat(data): DataStore settings repository mirroring iOS AppStorage keys"`

---

### Task 6: AppContainer + Application wiring

**Files:**
- Create: `di/AppContainer.kt`, `BeanBookApplication.kt`
- Modify: `app/src/main/AndroidManifest.xml` (add `android:name=".BeanBookApplication"`)

```kotlin
package com.beanbook.app.di

import android.content.Context
import androidx.datastore.preferences.preferencesDataStore
import androidx.room.Room
import com.beanbook.app.data.db.BeanBookDatabase
import com.beanbook.app.data.repo.*
import com.beanbook.app.data.settings.SettingsRepository

private val Context.dataStore by preferencesDataStore(name = "beanbook_settings")

/** Manual DI (spec §3): constructor injection from one composition root. */
class AppContainer(context: Context) {
    private val database: BeanBookDatabase = Room.databaseBuilder(
        context, BeanBookDatabase::class.java, "beanbook.db"
    ).build()

    val quotaPolicy: QuotaPolicy = UnlimitedQuotaPolicy
    val bagRepository = BagRepository(database.bagDao(), quotaPolicy)
    val brewRepository = BrewRepository(database.brewDao(), quotaPolicy)
    val brewPresetRepository = BrewPresetRepository(database.brewPresetDao(), quotaPolicy)
    val settingsRepository = SettingsRepository(context.dataStore)
}
```

```kotlin
package com.beanbook.app

import android.app.Application
import com.beanbook.app.di.AppContainer

class BeanBookApplication : Application() {
    val container: AppContainer by lazy { AppContainer(this) }
}
```

- [x] **Step 1: Implement; build green; commit** — `git commit -am "feat(di): AppContainer composition root + Application class"`

---

# M2 — Theme + design primitives

### Task 7: Palette system (all 11, light-locked)

**Files:**
- Create: `ui/theme/Palette.kt`, `ui/theme/Theme.kt`
- Test: `app/src/test/java/com/beanbook/app/ui/theme/PaletteTest.kt`

Ports `BeanBook/Shared/Theme/Palette.swift` + `Theme.swift`. **Transcribe every hex exactly** from the iOS file — all 11 palettes (forest, ocean, mocha, latte, honey, cascara, espresso, graphite, midnight, sage, plum), each with `background/card/ink/ink2/ink3/ink4/rule/accent/accentSoft/accentGlow/error/success`. `accentGlow = accent.copy(alpha = 0.22f)`.

Key requirements:
- `PaletteId` enum with raw strings; `canonical(raw)` legacy mapping: `"cocoa"→MOCHA`, `"slate"→OCEAN`, `"noir"→GRAPHITE` (port of `PaletteID.canonical`).
- Picker order (port of `Palette.all`): forest · latte, honey, cascara, mocha, espresso · ocean · graphite, midnight · sage, plum.
- `isPro` carried as data (forest is the only `isPro=false`); v1 does not gate on it (Decision 6).
- `LocalPalette = staticCompositionLocalOf { Palettes.forest }`; `object Theme { val palette: Palette @Composable get() = LocalPalette.current }` plus the non-color constants from `Theme.swift`: `screenPadding=24.dp, cardPadding=18.dp, cardSpacing=14.dp, itemSpacing=10.dp, cardRadius=14.dp, pillRadius=100.dp`.
- `BeanBookTheme(palette) { ... }`: provides `LocalPalette`, **`LocalContentColor provides palette.ink`** (without it, unlabeled Text/Icon render black — invisible on light palettes, black-on-black under midnight), **and** a `MaterialTheme` substrate with a FULL slot mapping so stock M3 components don't fall through to baseline purples: `lightColorScheme(primary=accent, onPrimary=White, primaryContainer=accentSoft, onPrimaryContainer=ink, background, onBackground=ink, surface=card, onSurface=ink, surfaceVariant=accentSoft, onSurfaceVariant=ink2, outline=rule, outlineVariant=ink4, error, onError=White)`. **Never** call `isSystemInDarkTheme()`, **no** `dynamicColorScheme` — the Compose analog of iOS's `.preferredColorScheme(.light)` lock. `midnight` is the only dark palette and only via manual selection.
- RoastLevel swatches (port of `RoastLevel+Swatch.swift`): light `C9A675`, mediumLight `A77742`, medium `8A4F2A`, mediumDark `5C3320`, dark `2E1810` — as a `RoastLevel.swatch: Color` extension in `Palette.kt`.
- Hex helper: `fun colorHex(hex: String) = Color(0xFF000000 or hex.toLong(16))`.

- [x] **Step 1: Failing JVM test** — `canonical("cocoa") == MOCHA`, `canonical("slate") == OCEAN`, `canonical("noir") == GRAPHITE`, `canonical("forest") == FOREST`, `canonical("garbage") == null`; `Palettes.all.size == 11`; `Palettes.all.first() == Palettes.forest`; only forest has `isPro == false`.
- [x] **Step 2: Run, FAIL.** **Step 3: Implement.** **Step 4: Run, PASS** (`testDebugUnitTest`).
- [x] **Step 5: Wire `MainActivity`** to read `settingsRepository.settings` (collectAsStateWithLifecycle), resolve `PaletteId.canonical(paletteId) ?: FOREST`, wrap content in `BeanBookTheme`. Placeholder content: a column of the 11 palette names, each `Text` in its palette's accent on `Theme.palette.background`.
- [x] **Step 6: Observation gate** — install/launch/screencap → background is forest `#FAFAF7`, 11 names visible. Commit: `git commit -am "feat(theme): 11-palette system, light-locked, with canonical id mapping"`

### Task 8: Motion tokens + editorial primitives

**Files:** Create `ui/theme/Motion.kt`, `ui/components/Eyebrow.kt`, `HairRule.kt`, `Pills.kt`, `DeltaCaption.kt`

Ports `Motion.swift` (5 intent-grouped tokens) and the core editorial vocabulary from `docs/design.md`.

Contracts (build each as a small composable + `@Preview`):
- **`Motion`** object: `transition` = tween(320ms, FastOutSlowIn), `control` = tween(200ms), `fade` = tween(250ms, ease-out), `fill` = tween(500ms, ease-out), `confirm` = spring(dampingRatio 0.6) — approximations of the iOS curves, same names/intents. Plus `@Composable fun rememberReduceMotion(): Boolean` reading `Settings.Global.ANIMATOR_DURATION_SCALE == 0f` (the Android analog of iOS Reduce Motion; the OS already nulls most animations when set, but Δ-caption/step transitions consult this explicitly per spec §5).
- **`Eyebrow(text, color = Theme.palette.ink3)`** — uppercase, 11sp, SemiBold, letterSpacing 1.2sp (port of `Eyebrow.swift`; "Don't use ad-hoc uppercase text" rule carries over).
- **`HairRule()`** — 0.5dp full-width divider in `Theme.palette.rule`. Every editorial list row starts with one.
- **`Pills.kt`** — three button composables (port of `GradientButtonStyle.swift` + design.md decision rule):
  - `PrimaryPill(text, onClick)` — solid `ink` capsule, white text ("advance a flow you're in": Next, Save brew, Begin).
  - `AccentPill(text, onClick)` — solid `accent` capsule + soft `accentGlow` shadow ("convert passive→active": empty-state CTAs).
  - `OutlinePill(text, onClick)` — hairline-outlined capsule (Back, timer Start/Pause).
- **`DeltaCaption(text)`** — 11sp, `ink3`, used under diverged fields ("was 18 g").

- [x] **Steps:** implement → previews render → `assembleDebug` green → temporary gallery screen behind the Task-7 placeholder (pills + eyebrow + rules on background) → screencap, observe → commit `feat(ui): motion tokens and editorial primitives (eyebrow, hair rule, pills)`.

### Task 9: Value primitives — BigRatio, RatioBar, RatioText, RatingDots, StarRating, StepperRow, RuleRow

**Files:** Create `ui/components/BigRatio.kt`, `RatingDots.kt`, `StarRating.kt`, `StepperRow.kt`, `RuleRow.kt`

Ports `BigRatio.swift`, `StarRating.swift`, the `StepperRow`/`StepperButton` privates of `NewBrewSheet.swift`, and `RuleRow.swift`. Contracts:

- **`BigRatio(ratio, size=96.sp, sub: String?)`** — serif "1 : X.XX", colon in accent, count-up animation on value change via `animateFloatAsState(Motion.transition)` (skipped under reduce-motion); optional eyebrow sub-line.
- **`RatioBar(ratio, height=4.dp)`** — accent fill share = `1/(1+ratio)`, rest `ink4`, animated with `Motion.fill`, rounded caps.
- **`RatioText(ratio)`** — inline `AnnotatedString`: "1" + accent bold ":" + "X.XX".
- **`RatingDots(value, size=5.dp)`** — `value` filled accent dots out of 5 (read-only).
- **`StarRating(rating: Int?, onRating)`** — 5 tappable dots, `Motion.control` scale feedback; used on Outcome step.
- **`StepperRow(label, value, unit, range, step=1.0, caption: String?, onValue)`** — HairRule top; label 14.5sp ink2 + optional `DeltaCaption` under it; − / + circular hairline buttons (34dp, press-scale 0.88) flanking a serif 24sp monospaced-digit value; clamps to `range`; haptic via `LocalHapticFeedback`.
- **`RuleRow(label, value)`** — hairline row with label ink2 left, value ink right (BrewDetail params).

- [x] **Steps:** implement with previews → `assembleDebug` → gallery screencap shows all primitives → commit `feat(ui): value primitives (ratio displays, rating, stepper rows)`.

---

# M3 — App shell

### Task 10: RootScaffold — bottom bar + center "+" + NavHost

**Files:**
- Create: `ui/navigation/RootScaffold.kt`
- Modify: `MainActivity.kt` (replace gallery with RootScaffold)

Port of `RootTabView.swift` reduced to v1 tabs (spec §5): **Today · Beans · + · Settings**.

Contract:
- Material3 `Scaffold` + `NavigationBar` with 4 slots ordered Today (`LocalCafe`), Beans (`ShoppingBag`), center **+** (`Add`, accent-tinted), Settings (`Settings`).
- The **+** item is NOT a destination: selecting it sets `newBrewRequest = NewBrewRequest()` and reselects the previous tab (port of the iOS `onChange(of: selection)` trick). `data class NewBrewRequest(val prefillBrewId: String? = null, val initialBagId: String? = null)`.
- `newBrewRequest != null` presents a **full-screen `Dialog`** (`usePlatformDefaultWidth = false`, `decorFitsSystemWindows = false`) hosting `NewBrewSheet` (placeholder `Text("NewBrew")` until M5). System Back inside = dismiss (iOS "Cancel" analog; Decision 10).
- Inner `NavHost` routes: `today`, `beans`, `settings` (tab roots) plus pushed: `brews` (brew list), `brew/{id}`, `bag/{id}`, `palettePicker`. Tab selection uses `popUpTo` + `launchSingleTop` (standard bottom-bar pattern).
- A `LocalNewBrewLauncher` composition local (`(NewBrewRequest) -> Unit`) so any screen can hot-start the flow without threading callbacks.
- NavigationBar colors from `Theme.palette`: container = `card`, selected = `accent`, unselected = `ink2`. Placeholder screens for `today`/`beans`/`settings` showing their route name.

- [ ] **Steps:** implement → `assembleDebug` → launch; screencap each tab + the "+"-opens-dialog behavior (screencap with dialog visible) → verify reselecting + does not change the highlighted tab → commit `feat(nav): root scaffold with bottom bar and center + presenting NewBrew`.

---

# M4 — Screens (each: read the cited iOS file first; copy is law)

### Task 11: Beans — bag list

**Files:** Create `ui/bags/BagListScreen.kt` (+ `BagListViewModel` in same file)

Port of `BagListView.swift`. Contract:
- Header: `Eyebrow("Beans · N open")` + serif 36sp "The shelf".
- Rows (scrolling `Column`, NOT `LazyColumn` Material list items — editorial styling, design.md): HairRule top; roast-level swatch bar 8×56dp rounded 4dp; eyebrow = brand (fallback "Bag") + `PushPin` 9sp accent icon when pinned; serif 22sp name (fallback "Untitled"); up to 3 tasting notes joined " · " 12sp ink2; trailing "N brews" 11sp ink3 + chevron.
- Sort: pinned first, then `createdAt` desc (port of `sortedBags`).
- Roast filter chip row (port of `RoastFilterRow` usage): All + 5 roast levels.
- **Long-press** row → context `DropdownMenu`: "Pin as default" / "Unpin" (`PushPin`/off) calling `bagRepository.togglePin` (iOS `.contextMenu` analog — no swipe actions, house rule).
- Tap row → navigate `bag/{id}`. Toolbar `Add` icon → `BagEditSheet` (Task 12).
- Empty state (verbatim): "The shelf is" / accent "empty." serif 36sp; body "Add a bag to track origin, roast date, and tasting notes. Linked to your brews automatically."; `AccentPill("Add a bag")`.
- ViewModel: `bagRepository.bags` + brew counts (`brewDao.observeAll()` grouped by bagId, or a small `@Query` count map) exposed as `StateFlow`.

- [ ] **Steps:** implement → build → seed 2 bags via the UI (Task 12 not yet done — temporarily insert via a debug button or do Tasks 11+12 together and verify after 12) → screencap list, pin via long-press, verify pinned floats to top with pin glyph → commit `feat(bags): editorial bag list with pin context menu`.

### Task 12: Bag add/edit sheet

**Files:** Create `ui/bags/BagEditSheet.kt`

Port of `NewBagSheet.swift` minus photo capture (Decision 2). Contract:
- Full-screen dialog, title "New bag" / "Edit bag"; Cancel left; **Save** right, enabled only when `brand.trim()` non-empty (iOS `isValid`).
- Sections (32dp spacing): Identity (brand*, name, origin), Characteristics (roast level segmented/chip selection of 5; process optional chip row of 6 + none; roast date: toggle "Roasted on" + `DatePickerDialog` — the iOS graphical date picker analog), Tasting (chip editor for tastingNotes: text field + add, tap chip to remove; notes multiline).
- Save: trim brand/name/origin; empty notes → null; `hasRoastedOn=false` → null date; create via `bagRepository.create` or update existing (hydrate fields when `editing != null`).
- Back/Cancel discards (no dirty-guard in v1; iOS's `interactiveDismissDisabled(isDirty)` noted in parity.md).

- [ ] **Steps:** implement → build → on emulator: add a bag with brand/name/roast/notes; edit it; screencap both → re-run Task 11 observation (pin, sort) → commit `feat(bags): add/edit bag sheet`.

### Task 13: Bag detail

**Files:** Create `ui/bags/BagDetailScreen.kt`

Port of `BagDetailView.swift`. Contract:
- Roast swatch color block 90×116dp rounded 6dp with soft swatch-tinted shadow; accent eyebrow = brand; serif 44sp name; meta line "origin · roastLevel · process" 13.5sp ink2.
- Tasting serif 24sp notes joined by accent " · "; optional notes paragraph 14sp ink2.
- Stats grid between HairRules, 3 cells: Brews count / "Avg ratio" (`1:X.XX` of brews with ratio>0, else "—") / "Roasted" (abbreviated date or "—").
- Brews list: eyebrow "N brew(s)"; rows method 14.5sp + relative time, trailing RatingDots + accent RatioText. Tap → `brew/{id}`.
- Toolbar overflow `Menu`: Edit (→ Task-12 sheet), Delete → confirm dialog **"Delete this bag?"** with message **"Brews on this bag will keep their settings but lose the bag link."** → `bagRepository.delete` + pop back (FK SET_NULL does the rest — already proven in Task 3 tests).

- [ ] **Steps:** implement → build → observe: detail renders, edit round-trips, delete keeps the brews (check via brew list once Task 14 lands; defer that single check if needed) → commit `feat(bags): bag detail with stats and delete-nullifies contract`.

### Task 14: Brew list + RecentShotsStrip

**Files:** Create `ui/brews/BrewListScreen.kt`, `ui/brews/RecentShotsStrip.kt`

Port of `BrewListView.swift` **scoped per spec §5 / Decision 4** (no search, no filter chips). Contract:
- Header: `Eyebrow("N logged")` + serif 36sp "Brews". Toolbar: Back (iOS "Done"), `Add` → NewBrew launcher.
- **RecentShotsStrip** (port of `RecentShotsStrip.swift`): shows when ≥2 brews; header eyebrow "Recent shots" + right-aligned "Tap to brew again" 11sp ink3; horizontal `LazyRow` of 150×130dp hairline cards (method icon+name 11sp ink3, serif 22sp `formattedRatio`, `formattedTime` 12sp + RatingDots, bag `displayTitle` or "No bag" 11sp ink3). **Tap card → `LocalNewBrewLauncher(NewBrewRequest(prefillBrewId = brew.id))`** — hot start.
- Saved-recipes entry row (only when presets exist): eyebrow "N saved", serif 22sp "Saved recipes", "Repeat what worked." 12sp ink2, chevron. v1: navigates to Settings' recipes section (Recipes screen is Phase 4); fine to make it non-navigating with the count if that's cleaner — note choice in parity.md.
- Rows: HairRule; serif 20sp method; detail "bagDisplayTitle · relative time" 12sp ink2; trailing accent RatioText 16sp + RatingDots. Tap → `brew/{id}`. **Long-press → DropdownMenu "Brew again"** (`Refresh`) → hot start (same launcher).
- Empty state (verbatim): "No" / accent "brews yet."; "Log your first brew to start dialing in your recipes."; `PrimaryPill("Log a brew")`.
- Relative time: `DateUtils.getRelativeTimeSpanString` (analog of iOS `.relative(presentation: .numeric)`).

- [ ] **Steps:** implement → build → observe with seeded brews (log via debug insert until M5; revisit observation after Task 23) → screencap → commit `feat(brews): chronological brew list with recent-shots strip and brew-again`.

### Task 15: Brew detail

**Files:** Create `ui/brews/BrewDetailScreen.kt`

Port of `BrewDetailView.swift`. Contract:
- Eyebrow = "MMM d, yyyy, h:mm a" datetime; serif 48sp method displayName; bag link (accent 13.5sp + arrow icon) → `bag/{id}`.
- Centered `BigRatio(size 96, sub "Xg · Yg · time")`, RatioBar(4dp, maxWidth 200dp) with "Dose"/"Yield" eyebrows under, RatingDots(8dp) when rated.
- Italic serif 20sp note section when notes exist (eyebrow "Note").
- Params via `RuleRow`: Dose "X g" / `yieldLabel`-derived label "X g" / Time `formattedTime` / **Water "94°C" only when `waterTempC != null`** (the Decision-1 surface) / Grind (value or "—").
- `PrimaryPill("Brew this again")` with `Refresh` icon → `LocalNewBrewLauncher(NewBrewRequest(prefillBrewId = id))`.
- Toolbar overflow: Delete → confirm "Delete this brew?" → delete + pop.

- [ ] **Steps:** implement → build → observe (incl. a pour-over brew showing the Water row, an espresso not showing it) → commit `feat(brews): brew detail with params and brew-this-again`.

### Task 16: Today (lean editorial home)

**Files:** Create `ui/today/TodayScreen.kt`

Port of `TodayView.swift`, simplified per spec §5. Contract:
- Toolbar: settings gear (ink2) → `settings` route.
- Eyebrow header: "Weekday, MMM d · First brew" / "· 1 brew" / "· N brews" (today's count).
- Hero: serif 36sp two-tone headline — "{Method}, like\nyesterday — but a touch " + accent italic "finer."; description 14sp ink2 (port `heroDescription`: bag displayTitle + "Same dose, pulled {time}." + optional "— yesterday's was {outstanding|great|solid|fine|off}."); `BigRatio(size 56, sub "Xg · Yg · time", leading)` + RatioBar(200dp); `PrimaryPill("Begin")` with arrow → NewBrew launcher (cold start).
- "Last logged" section: eyebrow + accent uppercase "All" button → navigate `brews`; 3 most-recent rows (serif 20sp method, "bagLabel · relative" 12sp, accent RatioText + RatingDots), tap → detail.
- Beans preview when bags exist: eyebrow "Beans · N open" + "All" → switch to Beans tab; 3 rows (serif 19sp name, "brand · roast" meta, roast swatch bar 5×30dp).
- Empty state (port `TodayEmptyView`, copy verbatim): eyebrow date; serif 44sp "Your\nfirst\n" + accent "brew."; body "BeanBook is a quiet place to log what you brew. No streaks, no scoring — just the recipe and how it tasted."; `AccentPill("Log a brew")`.

- [ ] **Steps:** implement → build → observe empty state AND populated state screencaps → commit `feat(today): lean editorial home`.

### Task 17: Settings + palette picker

**Files:** Create `ui/settings/SettingsScreen.kt`, `ui/settings/PalettePickerScreen.kt`

Port of `SettingsView.swift` minus Pro section and daily reminder (Phase 2/4), and of the palette-picking surface. Contract:
- Serif 36sp "Settings". Sections as card blocks (Theme.palette.card, hairline top+bottom) with eyebrow titles:
  - **General:** Units (dropdown Grams/Ounces → `preferredUnit`), Theme (navigable row showing current palette name → `palettePicker`), Default method (dropdown of 6 → `defaultBrewMethod`).
  - **Brewing:** "Auto-prefill from last brew" toggle (accent tint), "Timer style" dropdown Count down/Count up.
  - **Data:** read-only "Brews logged" / "Saved recipes" counts.
  - **Saved recipes** list (when any): method icon, name (fallback method displayName), "Xg → Yg" 12sp, trash delete. (This is v1's only preset management surface.)
- **PalettePickerScreen:** the 11 palettes in `Palettes.all` order, each row = name + 5 swatch dots (background/card/accent/accentSoft/ink) + selected ring; tap → `setPaletteId(id.raw)`; **theme changes app-wide immediately** (single `BeanBookTheme` at the root recomposes — this is the Task-7 wiring paying off).
- ⚠️ Copy rule: no Pro mentions anywhere (no Pro tier on Android v1; branding.md forbids un-led Pro copy).

- [ ] **Steps:** implement → build → observe: toggle auto-prefill persists across relaunch (`adb shell am force-stop com.beanbook.app` + relaunch); switch palette to midnight → whole app dark; screencap before/after → commit `feat(settings): settings + palette picker with live theme switching`.

---

# M5 — NewBrew flow (the spine)

### Task 18: NewBrewViewModel + hydration ladder (pure-JVM TDD — the core task)

**Files:**
- Create: `ui/newbrew/NewBrewViewModel.kt`
- Test: `app/src/test/java/com/beanbook/app/ui/newbrew/NewBrewViewModelTest.kt`

Port of the state/lifecycle logic of `NewBrewSheet.swift` (`hydrate`, `applyPrefill`, `applyMethodDefaultsIfFresh`, `save`, Δ-captions). For JVM testability the VM depends on three **interfaces** (implemented by the real repos via thin adapters or by making repos implement them directly):

```kotlin
interface BrewSource {
    suspend fun mostRecent(): BrewEntity?
    suspend fun byId(id: String): BrewEntity?
    suspend fun create(brew: BrewEntity): BrewEntity   // throws QuotaExceededException
}
interface BagSource {
    suspend fun pinned(): BagEntity?
    suspend fun byId(id: String): BagEntity?
}
interface PresetSink {
    suspend fun create(preset: BrewPresetEntity): BrewPresetEntity  // throws QuotaExceededException
}
```

State (port of the iOS `@State` block):

```kotlin
data class PrefillSnapshot(
    val dose: Double, val yieldG: Double, val brewTimeSeconds: Int, val grindSetting: String,
)

data class NewBrewUiState(
    val step: Int = 0,                       // 0 Context, 1 Shot, 2 Outcome
    val method: BrewMethod = BrewMethod.ESPRESSO,
    val bag: BagEntity? = null,
    val dose: Double = 18.0,
    val yieldG: Double = 36.0,
    val brewTimeSeconds: Int = 30,
    val grindSetting: String = "",
    val waterTempC: Double? = null,
    val rating: Int? = null,
    val notes: String = "",
    val saveAsPreset: Boolean = false,
    val presetName: String = "",
    val prefillSnapshot: PrefillSnapshot? = null,
    val recentBag: BagEntity? = null,        // "Recent: [bag]" swap chip when pin overrode recency
    val showSaved: Boolean = false,
) {
    val ratio: Double get() = BrewMath.ratio(dose, yieldG)
    val doseCaption: String? get() = prefillSnapshot
        ?.takeIf { it.dose != dose }?.let { "was ${BrewMath.formatGrams(it.dose)} g" }
    val yieldCaption: String? get() = prefillSnapshot
        ?.takeIf { it.yieldG != yieldG }?.let { "was ${BrewMath.formatGrams(it.yieldG)} g" }
    val timeCaption: String? get() = prefillSnapshot
        ?.takeIf { it.brewTimeSeconds != brewTimeSeconds }?.let { "was ${BrewMath.formattedTime(it.brewTimeSeconds)}" }
    val grindCaption: String? get() = prefillSnapshot
        ?.takeIf { it.grindSetting != grindSetting && it.grindSetting.isNotEmpty() }?.let { "was ${it.grindSetting}" }
    val ratingLabel: String get() = when (rating ?: 0) {
        0 -> "Tap to rate"; 1 -> "Off"; 2 -> "OK"; 3 -> "Good"; 4 -> "Great"; 5 -> "Outstanding"; else -> "—"
    }
    val stepTitle: String get() = when (step) {
        0 -> "What are you brewing?"; 1 -> "Pull the shot."; else -> "How was it?"
    }
}
```

ViewModel skeleton — the hydration ladder MUST implement this exact precedence (iOS `hydrate()`):

```kotlin
class NewBrewViewModel(
    private val brews: BrewSource,
    private val bags: BagSource,
    private val presets: PresetSink,
    private val settings: suspend () -> Settings,      // one-shot read at hydration
    private val prefillBrewId: String? = null,
    private val initialBagId: String? = null,
) : ViewModel() {

    private val _state = MutableStateFlow(NewBrewUiState())
    val state: StateFlow<NewBrewUiState> = _state.asStateFlow()

    private var didHydrate = false
    private var brewCommitted = false

    /** Hydration ladder — exact iOS precedence. (Phase 4 inserts prefillPreset above prefillBrew.) */
    suspend fun hydrate() {
        if (didHydrate) return
        didHydrate = true
        val s = settings()

        // 1. Hot start from an existing brew → land on Shot with snapshot.
        prefillBrewId?.let { id ->
            brews.byId(id)?.let { applyPrefill(it, jumpToShot = true); return }
        }
        // 2. Launched for a specific bag → that bag + default-method defaults.
        initialBagId?.let { id ->
            val bag = bags.byId(id)
            val method = BrewMethod.fromRaw(s.defaultBrewMethod)
            _state.update { it.copy(bag = bag, method = method) }
            applyMethodDefaultsIfFresh(method)
            return
        }
        // 3. Cold start + auto-prefill → hydrate from most recent; pinned bag overrides
        //    recency, surfacing the previous bag as a swap chip.
        if (s.autoPrefillFromLast) {
            brews.mostRecent()?.let { recent ->
                applyPrefill(recent, jumpToShot = false)
                val pinned = bags.pinned()
                if (pinned != null && pinned.id != recent.bagId) {
                    _state.update { st ->
                        st.copy(bag = pinned, recentBag = recent.bagId?.let { bags.byId(it) })
                    }
                }
                return
            }
        }
        // 4. True cold-cold start: method defaults + pinned bag if any.
        val method = BrewMethod.fromRaw(s.defaultBrewMethod)
        _state.update { it.copy(method = method) }
        applyMethodDefaultsIfFresh(method)
        bags.pinned()?.let { p -> _state.update { it.copy(bag = p) } }
    }

    private suspend fun applyPrefill(source: BrewEntity, jumpToShot: Boolean) {
        val bag = source.bagId?.let { bags.byId(it) }
        _state.update {
            it.copy(
                method = source.method,
                dose = source.doseGrams,
                yieldG = source.yieldGrams,
                brewTimeSeconds = source.brewTimeSeconds,
                grindSetting = source.grindSetting ?: "",
                waterTempC = source.waterTempC,
                bag = bag,
                prefillSnapshot = PrefillSnapshot(
                    source.doseGrams, source.yieldGrams,
                    source.brewTimeSeconds, source.grindSetting ?: ""
                ),
                step = if (jumpToShot) 1 else it.step,
            )
        }
    }

    /** iOS rule: method defaults must NEVER clobber prefilled values. */
    private fun applyMethodDefaultsIfFresh(method: BrewMethod) {
        if (_state.value.prefillSnapshot != null) return
        _state.update {
            it.copy(
                dose = method.defaultDose,
                yieldG = method.defaultYield,
                brewTimeSeconds = method.defaultTimeSeconds,
                waterTempC = method.defaultWaterTempC,
            )
        }
    }

    fun onMethodChange(method: BrewMethod) {
        _state.update { it.copy(method = method) }
        applyMethodDefaultsIfFresh(method)
    }

    fun onBagSelected(bag: BagEntity?) = _state.update { it.copy(bag = bag) }
    fun onDose(v: Double) = _state.update { it.copy(dose = v) }
    fun onYield(v: Double) = _state.update { it.copy(yieldG = v) }
    fun onTime(v: Int) = _state.update { it.copy(brewTimeSeconds = v) }
    fun onGrind(v: String) = _state.update { it.copy(grindSetting = v) }
    fun onRating(v: Int?) = _state.update { it.copy(rating = v) }
    fun onNotes(v: String) = _state.update { it.copy(notes = v) }
    fun onSaveAsPreset(v: Boolean) = _state.update { it.copy(saveAsPreset = v) }
    fun onPresetName(v: String) = _state.update { it.copy(presetName = v) }
    fun back() = _state.update { it.copy(step = (it.step - 1).coerceAtLeast(0)) }

    fun advance() {
        if (_state.value.step < 2) _state.update { it.copy(step = it.step + 1) }
        else viewModelScope.launch { save() }
    }

    /** Port of NewBrewSheet.save() — guard, trim-to-null, preset name fallback,
     *  preset failure still shows Saved (brew is already committed). */
    suspend fun save() {
        if (brewCommitted) return
        val st = _state.value
        val grind = st.grindSetting.ifEmpty { null }
        val notes = st.notes.ifEmpty { null }
        try {
            brews.create(BrewEntity(
                method = st.method, doseGrams = st.dose, yieldGrams = st.yieldG,
                brewTimeSeconds = st.brewTimeSeconds, grindSetting = grind,
                waterTempC = st.waterTempC, rating = st.rating, notes = notes,
                bagId = st.bag?.id,
            ))
            brewCommitted = true
        } catch (e: QuotaExceededException) {
            return   // v1: dormant (UnlimitedQuotaPolicy); Phase 2 routes to paywall here
        }
        if (st.saveAsPreset) {
            val name = st.presetName.trim().ifEmpty { "${st.method.displayName} recipe" }
            try {
                presets.create(BrewPresetEntity(
                    name = name, method = st.method, doseGrams = st.dose,
                    yieldGrams = st.yieldG, brewTimeSeconds = st.brewTimeSeconds,
                    grindSetting = grind, waterTempC = st.waterTempC,
                ))
            } catch (_: QuotaExceededException) { /* brew saved; overlay still shows */ }
        }
        _state.update { it.copy(showSaved = true) }
    }
}
```

- [ ] **Step 1: Write the failing tests first** (fakes for the three interfaces + a `settings` lambda; `runTest`):
  1. `coldStart_autoPrefillOn_hydratesFromMostRecent_andStaysOnContext` — values copied, snapshot set, `step == 0`.
  2. `coldStart_pinnedDiffersFromRecentBag_pinWins_andRecentChipSurfaces` — `bag == pinned`, `recentBag == recent's bag`.
  3. `coldStart_pinnedEqualsRecentBag_noChip` — `recentBag == null`.
  4. `coldStart_autoPrefillOff_usesMethodDefaults_andPinnedBag` — espresso defaults 18/36/30/null-temp, bag = pinned.
  5. `coldStart_noBrews_usesDefaultMethodSetting` — settings return `defaultBrewMethod = "pourOver"` → 22/350/210/94.
  6. `hotStart_prefillBrew_landsOnShot_withSnapshotAndBag`.
  7. `methodChange_onFreshForm_appliesDefaults` — change espresso→frenchPress → 30/500/240/96.
  8. `methodChange_afterPrefill_neverClobbersValues` — values unchanged after method change.
  9. `deltaCaptions_onlyOnDivergence` — equal → all null; dose 18→19 → `doseCaption == "was 18 g"`; time 30→35 → `"was 30s"`; grind caption null when snapshot grind was empty.
  10. `save_trimsEmptyGrindAndNotesToNull`.
  11. `save_presetNameEmpty_fallsBackToMethodRecipe` — "Espresso recipe".
  12. `save_calledTwice_createsExactlyOneBrew`.
  13. `save_presetQuotaDenied_brewStillSaved_showSavedTrue` — preset sink throws; brew created; `showSaved`.
  14. `hydrate_calledTwice_isIdempotent`.
- [ ] **Step 2: Run, verify FAIL.** — `./gradlew :app:testDebugUnitTest`
- [ ] **Step 3: Implement (code above).** **Step 4: Run, verify PASS.**
- [ ] **Step 5: Make the real repositories satisfy the interfaces** (`BrewRepository : BrewSource` etc. — direct implementation, no adapters needed) and add a `ViewModelProvider.Factory` companion taking `AppContainer` + `NewBrewRequest`. Build green.
- [ ] **Step 6: Commit** — `git commit -am "feat(newbrew): ViewModel with iOS-parity hydration ladder, delta captions, save semantics — 14 JVM tests"`

### Task 19: NewBrewSheet scaffold + Context step

**Files:** Create `ui/newbrew/NewBrewSheet.kt`, `ContextStep.kt`, `MethodPicker.kt`

Port of `NewBrewSheet.swift` chrome + `contextStep` + `MethodPicker.swift`. Contract:
- Top bar: "Cancel" (ink2) left → dismiss; center progress indicator = 3 capsules (active wider 26dp vs 16dp, accent vs rule, animated `Motion.transition`).
- Step header: `Eyebrow("Step N of 3")` + serif 32sp `stepTitle`; step content animated by `Motion.transition` (slide-forward + fade; instant under `rememberReduceMotion()`).
- Bottom bar over a background gradient: `PrimaryPill(if (step < 2) "Next" else "Save brew")` full-width → `vm.advance()`; "‹ Back" plain button when step > 0 → `vm.back()`.
- **Context step:** eyebrow "Method" + `MethodPicker` (vertical hairline rows: icon, serif 21sp name, selected = accent + semibold + trailing accent dot, `Motion.control`); HairRule; eyebrow "Bag" + accent "Pinned" 11sp label when selected bag is the pinned one; **"Recent: {displayTitle}" swap chip** (hairline capsule, undo icon) shown only when `recentBag != null && recentBag.id != bag?.id`, tap → `onBagSelected(recentBag)`; bag rows (roast swatch 6×38dp, brand eyebrow + pin glyph, serif 18sp name, selected accent + dot); final row "Skip — no bag" (accent when selected).
- `LaunchedEffect(Unit) { vm.hydrate() }`.
- When `state.showSaved`: saved overlay (Task 22) + auto-dismiss after 1400 ms.

- [ ] **Steps:** implement → build → observe: "+" cold start lands on Context, method change updates nothing visible yet but survives Next/Back; bag selection + Pinned label correct → screencap → commit `feat(newbrew): sheet scaffold, progress, context step`.

### Task 20: BrewTimer

**Files:** Create `ui/newbrew/BrewTimer.kt`

Port of `BrewTimer.swift` — the most stateful component; read the Swift file in full first. Contract:
- Phases: Idle / Running / Paused / Finished. `target` initialized from the bound `seconds` (clamped ≥5 s, ≤7200 s); the binding receives **elapsed** on pause/finish and **target** while idle (port of `commitElapsed`/`toggle`/`reset`).
- Eyebrow above readout: "Timer" / "Brewing" (accent) / "Paused" / "Done" (success).
- Readout: serif ~72sp ultralight monospaced `M:SS.t` (tenths); countdown shows remaining, countup shows elapsed (per `timerCountsDown` setting); "0:00" at rest endpoints. Color: accent while running, success when finished, ink otherwise. Drive with a frame-tick (`withFrameMillis` loop or `LaunchedEffect` + `delay(50)`) computing elapsed from a wall-clock `startMark` + `accumulated` — never an incrementing counter (background-safe; mirrors iOS `TimelineView` + `startDate` math).
- Progress rail: 220dp×2dp, fill = `elapsed/target`, accent → success on finish.
- Idle-only "−30s"/"+30s" hairline pills (bounds-guarded). Tap readout while idle → dialog with two `NumberPicker`-style wheels (minutes 0–120, seconds 0–59; Done disabled under 5 s total) → sets target + binding.
- Toggle pill (`OutlinePill`): "Start timer" / "Pause" / "Resume" / "Start over". Reset plain-text button visible when `phase != Idle || accumulated > 0`; preserves target.
- On finish (elapsed ≥ target while running): accumulated = target, binding = target, phase = Finished, haptic.
- On dispose (`DisposableEffect`): if running, freeze elapsed into the binding; elapsed==0 → binding = target (port of `commitElapsed` — "advance mid-run freezes elapsed time").

- [ ] **Steps:** implement → build → on-emulator observe: start, pause at ~5 s (readout freezes, binding visible in Shot step's time row after Task 21), resume, finish (success color + "Done"), reset; ±30s chips; edit-sheet path → commit `feat(newbrew): brew timer with idle/running/paused/finished phases`.

### Task 21: Shot step

**Files:** Create `ui/newbrew/ShotStep.kt`

Port of `shotStep` in `NewBrewSheet.swift`. Contract:
- Top: `BigRatio(state.ratio, size 84)` + `RatioBar(3dp, maxWidth 220dp)` — live as dose/yield change.
- `StepperRow("Dose", value, "g", method.doseRange, caption = state.doseCaption)`; `StepperRow(yieldLabel-stripped("Yield"/"Water"), …, method.yieldRange, caption = state.yieldCaption)` — captions are the Δ-from-last hints, animated with `Motion.control` (instant under reduce-motion).
- `BrewTimer(seconds = state.brewTimeSeconds, countsDown = settings.timerCountsDown, onSeconds = vm::onTime)` + `DeltaCaption(state.timeCaption)` under it when non-null.
- Grind row (port of `GrindRow`): hairline row, label "Grind" + optional caption; right-aligned serif 22sp `TextField` placeholder "e.g. 2.4", Done IME action.
- **No water-temp control** (Decision 1).

- [ ] **Steps:** implement → build → observe cold start: espresso defaults 18/36/30; switch method on Context → Shot shows new defaults; no Δ-captions on cold-cold start → commit `feat(newbrew): shot step with live ratio, steppers, timer, grind`.

### Task 22: Outcome step + save + saved overlay

**Files:** Create `ui/newbrew/OutcomeStep.kt`; modify `NewBrewSheet.kt` (overlay)

Port of `outcomeStep` + `savedOverlay`. Contract:
- Centered `StarRating(24dp)` + eyebrow `ratingLabel` ("Tap to rate" / Off / OK / Good / Great / Outstanding).
- HairRule; eyebrow "Note" + serif 17sp multiline `TextField` placeholder **"How did it taste?"** (3–6 lines).
- HairRule; "Save as recipe" toggle (accent); when on, "Recipe name" field appears.
- "Save brew" → `vm.advance()` → save. On `showSaved`: full-screen overlay at 92% background opacity — accent circle 76dp + white check (scale-in `Motion.confirm`, instant under reduce-motion), serif 22sp **"Saved."**, "1:X.XX · time" 13sp ink2; auto-dismiss the whole sheet after **1400 ms** (`LaunchedEffect(showSaved) { delay(1400); onDismiss() }`).

- [ ] **Steps:** implement → build → full cold-start run on emulator: Context→Shot→Outcome→rate 4→note→save-as-recipe named "Morning dial-in"→Save → overlay → auto-dismiss → brew appears on Today + BrewList; recipe appears in Settings; relaunch app (`force-stop` + start) → data persisted → screencaps → commit `feat(newbrew): outcome step, save semantics, saved overlay`.

### Task 23: Hot-start wiring across all surfaces

**Files:** Modify `RootScaffold.kt` (launcher plumbs `NewBrewRequest` into the VM factory), `RecentShotsStrip.kt`, `BrewListScreen.kt`, `BrewDetailScreen.kt`

Contract (spec §5 hot-start surfaces): RecentShotsStrip tap, brew-row long-press "Brew again", BrewDetail "Brew this again" — all → `NewBrewRequest(prefillBrewId)` → flow opens **on Shot** with values prefilled and snapshot set.

- [ ] **Steps:** wire → build → on-emulator observe each surface: opens on "Pull the shot."; change dose 18→19 → `DeltaCaption "was 18 g"` appears under Dose; change method on Context after Back → values NOT clobbered (the Task-18 invariant, now visible) → save → new brew logged → commit `feat(newbrew): hot-start from strip, list context menu, and detail`.

---

# M6 — Acceptance

### Task 24: Compose UI tests

**Files:** Create `app/src/androidTest/java/com/beanbook/app/ui/NewBrewFlowTest.kt`

Analog of the iOS XCUITest suite, scoped to the flow contracts (spec §7):

- [ ] **Step 1: Write tests** with `createAndroidComposeRule<MainActivity>()`; seed data via `(context.applicationContext as BeanBookApplication).container` repositories in `@Before` (runBlocking):
  1. `coldStart_walksThreeSteps_andSaves` — tap "+" (contentDescription "Log brew") → assert "What are you brewing?" → "Next" → "Pull the shot." → "Next" → "How was it?" → "Save brew" → "Saved." appears.
  2. `hotStart_fromRecentShot_landsOnShot` — seed bag + 2 brews → open Brews → tap a recent-shot card → assert "Pull the shot." visible immediately.
  3. `deltaCaption_rendersOnDivergence` — hot start → tap dose "+" once → assert text starting "was " exists.
  4. `pinnedBag_winsOverRecency_withSwapChip` — seed bagA (recent brew) + bagB (pinned) → cold start "+" → assert "Pinned" label and "Recent: " chip both present on Context.
- [ ] **Step 2: Run** — `./gradlew :app:connectedDebugAndroidTest` → all green (fix app or tests as needed; tests must observe real behavior, no stubs).
- [ ] **Step 3: Commit** — `git commit -am "test(ui): compose UI tests for 3-step flow, hot start, delta captions, pin override"`

### Task 25: Parity checklist + README

**Files:** Create `docs/parity.md`, `README.md` (Android repo)

- [ ] `parity.md` (spec §2 requires it): table — feature | iOS | Android v1 status | phase. Rows at minimum: every M4/M5 surface (✅), brew-list search + filter chips (Phase 4), Recipes browsing screen (Phase 4), bag/brew photo capture (Phase 4, columns already shipped), onboarding (Phase 4, key reserved), Pro/paywall + quota enforcement + palette gating (Phase 2 — **flag the grandfathering decision and the Family-Sharing/Play-family-library copy reconciliation from spec §8**), Stats (Phase 2), Shop/Discover + location (Phase 3), notifications/daily reminder (Phase 4), custom serif font + dirty-guard on bag edit (Phase 4 polish), first-frame forest flash on cold launch before DataStore emits a saved non-forest palette (Phase 4 polish — splash/theme-preload).
- [ ] `README.md`: project summary, the verified build/test/emulator commands (from this plan's header), pointer to the iOS repo's `branding.md`/`design.md` as cross-platform law, and the parity doc.
- [ ] Commit — `git commit -am "docs: parity checklist and README"`

### Task 26: Final acceptance — walk spec §10 on the emulator

- [ ] **Step 1:** Fresh install (`adb uninstall com.beanbook.app`, `./gradlew :app:installDebug`), then walk the checklist, screencapping each: ① create a bag, edit it, pin it ② log a brew cold-start through all 3 steps ③ view brew list + detail ④ re-brew from prefill (hot start, Δ-caption seen) ⑤ save a recipe and see it in Settings ⑥ switch theme to midnight and back ⑦ `force-stop` + relaunch → everything persisted.
- [ ] **Step 2:** Full test sweep: `./gradlew :app:testDebugUnitTest :app:connectedDebugAndroidTest` → green.
- [ ] **Step 3:** Cross-check every parity.md "✅" row against what you just observed; fix or re-status anything that doesn't hold.
- [ ] **Step 4:** Commit any fixes; tag `v1.0-mvp` in the Android repo. In the **iOS repo**, move this plan to `docs/superpowers/plans/completed/` in its own commit.

---

## Post-plan notes for the executor

- **Emulator lifecycle:** instrumented gates and observation gates need the AVD booted; boot once and reuse. If `connectedDebugAndroidTest` hangs, check `adb devices` shows exactly one device.
- **If a dependency fails to resolve** (the pins were verified 2026-06-06 but Maven moves): query the live metadata (`https://dl.google.com/android/maven2/<group-path>/group-index.xml`, `https://repo.maven.apache.org/maven2/.../maven-metadata.xml`), pick the nearest stable, re-run the Task-1 ladder before continuing.
- **Material icons:** if `material-icons-extended` is unavailable under the 2026 BOM, fall back to `androidx.compose.material:material-icons-core` + inline the few missing `ImageVector`s.
- **Never** add `org.jetbrains.kotlin.android` (AGP 9 hard-errors), and never set `compileSdk < 37` while on core-ktx 1.19.0.
