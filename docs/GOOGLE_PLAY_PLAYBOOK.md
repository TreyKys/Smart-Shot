# Google Play Release Playbook

This is the accumulated knowledge from actually shipping Sift to Google Play —
not the happy-path docs, the version with every pitfall we hit along the way.
If you're doing this again (a second app, a fresh machine, onboarding someone
else), read the "What can go wrong" subsections before you start, not after
you're stuck.

Scope: Play Console app setup, release signing, building and uploading the
AAB, and RevenueCat/Play Billing integration. For app-internal architecture
decisions (Remote Config, background sync, etc.), see the commit history —
this doc is specifically the external-service, "why is Play Console yelling
at me" knowledge.

---

## 1. Play Console: creating the app

**Package name:** `com.neurodevlabs.sift` — already set as `applicationId` in
`android/app/build.gradle.kts`. This is **locked forever** the moment you
upload a build to any release track, including internal testing. There is no
"just change it later."

### Prerequisite that blocks everything else

Play Console will not let you create paid products — subscriptions, one-time
products, nothing — until you have a **payments profile** set up: **Settings
→ Developer account → Payments profile → Create payments profile**. Needs
real business info and a bank account in the same country as the profile.

This has no dependency on anything else in this doc. If you're setting up a
new app, do this first, in parallel with everything else, because it's the
slowest human-approval step and blocks the RevenueCat section entirely.

### What can go wrong

- Trying to create a subscription with no payments profile: Play just won't
  let you, sometimes without a clear error explaining why.

---

## 2. Release signing

### The setup, once it's correct

`android/key.properties` (gitignored, per-machine — never committed, never
synced by git):
```properties
storePassword=<the keystore password>
keyPassword=<the key password — can be the same as storePassword>
keyAlias=sift-upload
storeFile=upload-keystore.jks
```

Critical detail: `storeFile` is a **bare filename**, not a path with `app/`
in front of it. `android/app/build.gradle.kts` resolves it via
`file(keystoreProperties["storeFile"] as String)` — and that `file()` call
runs inside the `:app` module's own build script, so it resolves relative to
`android/app/`, **not** to `android/` where `key.properties` itself lives.
Writing `storeFile=app/upload-keystore.jks` (a reasonable guess if you're
thinking "relative to where key.properties is") produces a doubled path —
Gradle looks for `android/app/app/upload-keystore.jks` and fails with
`Keystore file '...' not found for signing config 'release'`.

The keystore itself lives at `android/app/upload-keystore.jks` — also
gitignored, also per-machine, also never synced.

`build.gradle.kts` falls back to debug signing automatically when
`key.properties` doesn't exist, specifically so `flutter run --release` still
works on a machine with no keystore (CI, a fresh clone). This is
intentional and by design — but it means a **missing key.properties fails
silently into debug signing**, not with an error. Keep that in mind when
debugging anything signing-related: "no error" doesn't mean "using the real
key."

### Generating a keystore for the first time

```bash
cd android/app
keytool -genkeypair -v \
  -keystore upload-keystore.jks \
  -alias sift-upload \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storetype PKCS12
```

It'll ask for a password and then Distinguished Name fields (name,
organization, city, country). Put real values in — **never leave these as
placeholder/example text**, and specifically never let this end up looking
like `CN=Android Debug, O=Android, C=US` (see the postmortem below for why
that's not a hypothetical).

### The one thing that cannot be undone

**Back up `upload-keystore.jks` and its password somewhere outside whatever
cloud workspace you're building in, immediately after generating it.** This
file is the *only* key that can ever sign an update to this app on Play,
forever. Lose it, and you cannot push an update to this app again under this
package name — you'd have to publish a new app from scratch and lose every
existing user, review, and ranking.

This is not a theoretical warning — we generated a keystore this session on
a Firebase Studio workspace, a cloud environment with a hard 10–15GB disk
quota that we ran completely out of space on more than once during this same
session. Download the file to a real computer and put the password in an
actual password manager. Two minutes now, unrecoverable later.

### Verifying a build is actually release-signed (do this before every upload)

An `.aab` is jar-signed under the hood, so `keytool` reads it directly — no
extra tooling needed:

```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

Compare the `Owner:` line and `SHA256:` fingerprint against what you expect.
**`CN=Android Debug, O=Android, C=US` is the unmistakable debug identity** —
if you see that, the build did not use your real keystore, full stop. Make
this a standing habit before every single upload; it takes five seconds and
would have saved hours this session.

### What can go wrong (the actual postmortem)

This was, by a wide margin, the hardest part of the whole release process.
In order, what we hit and how we found each one:

1. **Disk space.** Firebase Studio workspaces get a fixed ~10–15GB with no
   upgrade path for an existing workspace. A Flutter release build pulls in
   the Android SDK, Gradle's dependency cache, and multiple Gradle
   distribution versions — that's genuinely tight. Symptom:
   `java.io.IOException: No space left on device`, often wrapped in
   confusing secondary Gradle errors about cache/binary-store writes. Fix:
   check `df -h ~`, then clear the actual offenders —
   `~/.gradle/caches`, `~/.gradle/wrapper/dists`, and any stray
   `node_modules` from abandoned experiments. Do **not** touch `~/.pub-cache`
   unless truly desperate; it's shared and rarely the real offender.

2. **Stale Gradle daemon lock.** After a build crashes from disk exhaustion,
   killing the daemon with a plain `pkill -f gradle` (SIGTERM) can leave it
   half-dead, holding a lock file it never released. Symptom: `Cannot lock
   file hash cache (...) as it has already been locked by this process`. Fix:
   `pkill -9 -f gradle` (force kill), then delete the per-project
   `android/.gradle` directory (different from the global `~/.gradle`) and
   rebuild.

3. **The `storeFile` doubled-path bug** — described above in detail. Symptom:
   `Keystore file '.../android/app/app/upload-keystore.jks' not found`.

4. **The real one: a debug-flavored "release" keystore.** After fixing the
   above, builds succeeded — but `keytool -printcert` on the resulting `.aab`
   showed `Owner: CN=Android Debug, O=Android, C=US`. We spent a long time
   suspecting Gradle itself (build cache serving a stale output, a duplicate
   config block, a Flutter Gradle plugin override) and added diagnostic
   `println` statements at every stage of the signing config resolution —
   all of which came back clean: correct file path, `hasReleaseKeystore =
   true`, correct alias read, correct `signingConfig` assigned, confirmed
   even in `afterEvaluate` after every plugin had run. Disabling the Gradle
   build cache entirely and clearing its cache directory changed nothing
   either. **The actual cause: the keystore file itself contained a
   certificate with `CN=Android Debug`**, under the alias `upload` — not a
   genuine, unique release identity, and not even the alias name
   (`sift-upload`) that `key.properties` on that machine expected. Two
   separate gitignored files (a `key.properties` and an `upload-keystore.jks`
   from an earlier point in setting up this project) had drifted out of
   sync with each other and with what the working repo's own
   `key.properties.example` implied. Gradle's configuration model was
   correct the entire time — it was faithfully using whatever was actually
   in the file, which simply wasn't a real key.
   **Lesson: when a build succeeds cleanly but produces the wrong signature,
   suspect the keystore's actual contents before you suspect the build
   tool.** `keytool -list -keystore <file> -storepass <pass>` — listing what's
   actually inside the file — is a five-second check that would have found
   this immediately, and should be step one next time, not a last resort.

5. **jarsigner as a bypass, and its own gotcha.** While chasing #4, we tried
   manually re-signing the already-built `.aab` directly with `jarsigner`
   (valid — an `.aab` is just a signed zip), bypassing Gradle's signing task
   entirely:
   ```bash
   jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
     -keystore android/app/upload-keystore.jks \
     -storepass "$STOREPASS" -keypass "$KEYPASS" \
     build/app/outputs/bundle/release/app-release.aab \
     <alias>
   ```
   First attempt failed with `Certificate chain not found for: <alias>` — the
   store password was accepted but the specific alias couldn't be unlocked.
   Turned out the alias itself was simply wrong (see #4) — once corrected
   to match what `keytool -list` actually showed, this becomes a legitimate
   fallback path if Gradle's signing ever misbehaves independently of the
   keystore's contents being correct.

### Cleaning a build for a fresh, unambiguous rebuild

When in doubt about whether you're looking at a stale artifact:
```bash
rm -rf build/app/outputs/bundle
flutter build appbundle --release --dart-define-from-file=dart_define.json
```
Deleting the output directory first removes all ambiguity about whether
Gradle actually re-ran the packaging/signing step or you're looking at
leftovers from an earlier attempt.

---

## 3. Building and uploading the AAB

Standard build:
```bash
flutter build appbundle --release --dart-define-from-file=dart_define.json
```
Output: `build/app/outputs/bundle/release/app-release.aab`.

**Verify with `keytool -printcert` (section 2) before uploading. Every
time.**

### Getting the file out of a broken cloud workspace

If the workspace's file explorer isn't cooperating, the file can be pushed
to a git branch temporarily and downloaded via GitHub's raw URL — this is a
legitimate but *temporary* workaround, not a pattern to repeat every release:
```bash
git add -f build/app/outputs/bundle/release/app-release.aab
git commit -m "Temporary: add release AAB for direct download"
git push origin <branch>
```
Download: `https://raw.githubusercontent.com/<owner>/<repo>/<branch>/build/app/outputs/bundle/release/app-release.aab`

**Remove it again once downloaded** — `git rm` and push. An `.aab` is tens of
MB and git doesn't diff binaries; repeating this every release just grows
the repo's history forever with no way to shrink it back short of rewriting
history. Prefer downloading directly from the workspace's file explorer, or
uploading straight from the workspace's browser tab into Play Console's
upload widget — no git involved at all.

### Uploading to Closed Testing

Play requires the app to exist on a release track (internal, closed, or
open) at least once before license testers can make test purchases —
subscriptions can't be meaningfully tested without this.

**Testing → Closed testing → Create release** → upload the `.aab` → fill in
release notes → **Save → Review release → Start rollout**.

If uploading via the "upload release notes from a file" option instead of
typing directly, the expected format is a bare locale code on its own line,
then the note text below it — no brackets, no XML:
```
en-US
Initial closed testing release.
```

### What can go wrong

- **"You uploaded an APK or Android App Bundle that was signed in debug
  mode."** — Play's own validation catching exactly the section-2 problem.
  Re-verify with `keytool -printcert` before re-uploading; don't just retry
  blindly.
- Uploading a stale file from an earlier build attempt, distinguishable from
  a fresh one only by actually checking — `find build -iname "*.aab"` to
  make sure you're not confusing `bundle/release/app-release.aab` with a
  leftover `bundle/debug/app-debug.aab` from local testing.

---

## 4. RevenueCat + Google Play Billing

### 4.1 Prerequisite: Google Cloud service account

RevenueCat needs server-to-server access to Play, via a dedicated Google
Cloud service account — not your personal login.

1. In Google Cloud Console, create/select a project (can be separate from
   Firebase's project, they're unrelated).
2. Enable: **Google Play Developer API**, **Google Play Developer Reporting
   API**, **Cloud Pub/Sub API**.
3. **IAM & Admin → Service Accounts → Create Service Account.**
4. Grant it **Pub/Sub Editor** and **Monitoring Viewer** roles.
5. **Keys → Add Key → Create new key → JSON.** Download it — treat this file
   as a credential, same care as the Gemini key or the upload keystore.

### 4.2 Grant Play Console access to that service account

**Play Console → Users and permissions → Invite new user** → paste the
service account's email (the `client_email` field in the JSON, looks like
`name@project.iam.gserviceaccount.com`). Grant **View financial data** and
**Manage orders and subscriptions**.

**This step can take real time to actually activate** — invite it early and
do other setup while it settles, rather than blocking on it.

### 4.3 RevenueCat: connecting the app

**App Settings → Service credentials (Google Play)** → upload the JSON key
from 4.1. This only works once the Play Console invite in 4.2 shows
**Active**.

### 4.4 Creating the actual product in Play Console

`Monetize → Products → Subscriptions → Create subscription`.

- **Product ID**: lowercase/numbers/underscores/periods, ≤40 chars,
  **cannot be changed or reused once created**. Keep duration out of the ID
  (`sift_pro`, not `sift_pro_monthly`) — duration is expressed by the base
  plan, and one subscription can hold multiple base plans (monthly, annual,
  etc.).
- **Base plan**: **Add base plan** → set billing period and renewal type
  (auto-renewing) → set a default price → **Activate**. An unactivated base
  plan is invisible to both users and RevenueCat.
- **Regional pricing**: enter one reference price (e.g. `$2.99` USD), which
  Play auto-converts for every other market. Then use the **Adjust
  prices**/per-country table to override specific countries to an exact
  value — e.g. Nigeria set to `₦900` rather than the USD-converted figure.

### 4.5 RevenueCat: Entitlement → Offering → Package

1. **Entitlements → +New**, identifier exactly **`pro_entitlement`** — this
   string is hardcoded in `lib/features/pro/pro_service.dart` in three
   places. Any other spelling and Pro silently never activates, with no
   error anywhere.
2. Open the entitlement → **Attach** → select the product from 4.4.
3. **Offerings → +New**, mark it **Current** — `Purchases.getOfferings().current`
   in the app resolves to whichever Offering is marked Current, and there
   can only be one.
4. Inside it, **Add package** → **Identifier** must be one of RevenueCat's
   standardized values, not a custom string:
   - `$rc_monthly` for a monthly product
   - `$rc_annual` for an annual product
   This determines the SDK's `Package.packageType` at runtime, which
   `lib/features/pro/presentation/paywall_sheet.dart` uses to decide which
   badge to show (`"SAVE 30%"` for annual, `"OWN IT FOREVER"` for lifetime).
   A custom identifier here silently maps to `PackageType.custom` — purchases
   still work, but the badges never appear and nothing logs why.

### 4.6 Wiring the API key into the app

`dart_define.json` (gitignored, per-machine — same category as
`key.properties`):
```json
"REVENUECAT_ANDROID_API_KEY": "goog_..."
```
From **Project settings → API keys → Android** in RevenueCat — the public
key, starts with `goog_`, safe to have in this file (unlike the keystore
password, this key is meant to ship inside the compiled app). Read via
`AppConfig.revenueCatAndroidApiKey` in `lib/features/pro/pro_service.dart`,
which calls `Purchases.configure()` whenever it's non-empty.

### What can go wrong

- **Building on a different machine than the one you last edited
  `dart_define.json` on.** It's gitignored, so it never syncs via git —
  every environment that runs `flutter build` needs its own copy with the
  real key pasted in. This bit us directly this session: editing the file
  in one sandbox does nothing for a build run in a separate cloud
  workspace.
- **A single-package Offering and a hardcoded "select the second item"
  UI assumption.** `paywall_sheet.dart` originally hardcoded
  `_selectedIndex = 1` assuming an annual package always existed at that
  position. With only a monthly base plan configured (no annual tier yet),
  `availablePackages` has exactly one entry, and indexing position `1`
  throws `RangeError` the moment the purchase button is tapped. Fixed to
  search by `packageType` instead of assuming a fixed position — correct
  whether there's one package or several, regardless of dashboard ordering.
  Worth remembering if you ever go back to a single-tier offering after
  having multiple: the code should already handle it, but it's the kind of
  assumption that's easy to reintroduce by accident in future edits.
- **Entitlement identifier typos.** `pro_entitlement` has to match exactly,
  character for character, between the RevenueCat dashboard and
  `pro_service.dart`. There is no validation step that catches a mismatch —
  it just silently means Pro never turns on for anyone, forever, with no
  error, no crash, nothing in the logs pointing at it.

### 4.7 Testing an actual purchase

Real purchases can't be tested with your own regular Google account.

1. Upload the app to **any** test track at least once (section 3) — Play
   requires this before test purchases work at all.
2. **Play Console → Settings → License testing** → add your test Gmail.
3. When that account initiates a purchase, Play substitutes test payment
   instruments (an always-succeeds card, an always-declines card) instead of
   real payment methods — lets you verify both the happy path and failure
   handling without spending real money.

---

## Quick-reference: what lives where, and what doesn't sync

| File | Tracked in git? | Notes |
|---|---|---|
| `android/key.properties` | No (gitignored) | Per-machine. Keystore path/passwords. |
| `android/app/upload-keystore.jks` | No (gitignored) | Per-machine. **Back this up separately, outside any single workspace.** |
| `dart_define.json` | No (gitignored) | Per-machine. RevenueCat/Gemini/AdMob keys. |
| `dart_define.example.json` | Yes | Template — copy this to create `dart_define.json` on a new machine. |
| `android/key.properties.example` | Yes | Template for `key.properties`. |

The practical consequence of all three secrets files being gitignored: every
new environment you build release APKs/AABs from — a new laptop, a fresh
cloud workspace, a teammate's machine — needs its own copies of all three,
populated by hand. Nothing about `git clone` or `git pull` brings them along.
That's intentional (they're secrets), but it's also exactly the kind of gap
that produces a "why does this build differently here than it did there"
afternoon if you forget it.
