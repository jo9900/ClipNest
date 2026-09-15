# Review and verification — September 15, 2026

## Result

Seven behavior tests pass. Debug and universal Release builds succeed with Xcode
26.6 on macOS 26.6.2. The Release executable contains `arm64` and `x86_64` slices;
its only entitlement is App Sandbox. A development-signed archive also succeeds.

Reviewed the complete path from pasteboard polling through bounded storage,
selection, clipboard write, panel dismissal, and restoration of the previous app.

## Findings fixed

- Closing the panel synchronously triggered a second dismissal callback, clearing
  the application that should regain focus. The restore target is now captured
  before ordering out the window. Reproduced before the fix; after the fix, Return
  closes the panel and Finder becomes frontmost again.
- Search focus was requested before the panel became key. It is now requested on
  the next main-loop pass; runtime inspection confirms the search field is focused.
- Panel key handling now lets an input method handle marked text before considering
  Return, arrows, or Escape. Empty history also passes Return through to native controls.
- Pause is persisted so relaunching does not silently resume recording.
- Release signing no longer injects the development debugger entitlement.
- Clipboard access status changes publish only when the message actually changes.

## Checks completed

- Storage: limit/eviction, deduplication, exact Unicode and whitespace, persistence,
  permissions, whitespace-only/oversized input, deletion and clearing, malformed
  saved data, duplicate IDs/content on load, and failed writes.
- Isolated pasteboard: consent, concealed/transient markers, pause/resume, persisted
  pause, own-copy suppression, and preventing immediate re-capture after clearing.
- Selection: case/diacritic-insensitive search, empty results, navigation bounds,
  and a selected entry being deleted.
- Runtime: global shortcut from Finder, search, Return/dismissal and focus return,
  native settings, clear confirmation/cancel/clear, light and dark appearance.
- Login Items registration enabled successfully and then disabled again, verified
  by the settings switch. No actual logout/login was performed.
- Plists validate; Release code signature verifies; screenshots export as opaque
  1280 × 800 PNGs. UI review uses an isolated clipboard and sample history.

## Remaining validation

- Run on physical Intel hardware and macOS 13; both are build targets, but this Mac
  only provides Apple silicon and macOS 26 for execution.
- Confirm login-time launch after a real logout/login and full-screen/multiple-display
  behavior on the owner's arrangement.
- Exercise the macOS clipboard permission dialog's denial and approval paths on
  a fresh signed install. Current automated tests use a private pasteboard.
- App Store distribution signing, upload and Apple review require a working Xcode
  account session and the corresponding distribution assets.
