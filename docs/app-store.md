# Mac App Store preparation

Status: prepared for owner submission; **not submitted or approved**.

The `docs/screenshots/app-store-light.png` and `app-store-dark.png` files are opaque
1280 × 800 PNGs composed from actual app-window captures with isolated sample clips.
The original captures are beside them. To reframe a fresh window capture:

```sh
swiftc scripts/frame-screenshot.swift -o build/frame-screenshot
build/frame-screenshot input.png output.png light
```

## App record

| Field | Value |
| --- | --- |
| Name | ClipNest (confirm availability in App Store Connect) |
| Subtitle | A home for your last 20 copies |
| Version / build | 1.0.0 / 1 |
| Bundle ID | com.jo9900.ClipNest |
| Category | Productivity |
| Minimum macOS | 13.0 |
| Download price | Free (0) |
| In-app purchases / subscriptions | None |
| Support URL | https://github.com/jo9900/ClipNest/issues |
| Privacy policy URL | https://github.com/jo9900/ClipNest/blob/main/docs/privacy.md |
| Data collection | Data Not Collected; nothing leaves the device |
| Keywords | clipboard,history,copy,paste,text,links,productivity,menu bar |

## Description

Keep the useful things you copy within reach.

ClipNest saves your latest 20 text clips and links in a quiet, centered panel. Open
it with Option–Command–V or the menu bar, search your recent copies, and choose one
to use again. Your selection goes back onto the clipboard, ready to paste into your app.

- Your latest 20 copies, with older entries removed automatically.
- Search, arrow-key navigation, and Return to copy.
- Escape or a click outside to dismiss.
- Clear all history or delete a single entry.
- Optional launch at login and pause recording.
- Local storage, without accounts, analytics, or cloud services.

Supports plain text and links on macOS 13 or later. ClipNest does not automatically
type into other apps; press Command–V after choosing your clip.

## Review notes

ClipNest is a menu bar application (LSUIElement). After launch, click Start Saving
History, then copy text in another app. Open the history panel by clicking the menu
bar icon or pressing Option–Command–V. Click a row or press Return to put that text
on the system clipboard; the panel closes and returns focus to the previous app.
Paste using Command–V. Escape closes the panel without copying.

Use the gear button for launch at login and pause. Right-click the menu bar icon to
quit. Clear All deletes persisted history and requires confirmation. The system
clipboard stays unchanged by Clear All. No login or demo account is required.

The app runs inside App Sandbox with no additional entitlements and no network access.
It uses NSPasteboard, a registered Carbon hotkey, and SMAppService.mainApp for login.
On systems with pasteboard access restrictions, grant ClipNest ongoing clipboard
access in System Settings. It does not request Accessibility permission or inject
keyboard input into other applications.

## Owner submission steps

1. Use an enrolled Apple Developer team with App Store Connect access. Register the
   bundle ID, confirm the product name is available, and create a macOS app record.
2. In Xcode, select that team for ClipNest. Keep App Sandbox and hardened runtime
   enabled. Create/obtain the Mac App Store distribution signing assets. This repo
   intentionally contains no team ID, private certificate, profile, or API key.
3. Run tests and test a signed Release build on the oldest supported macOS and an
   Intel Mac. Check onboarding, pasteboard permission grant/denial/recovery, keyboard
   and mouse selection, full-screen and multiple displays, clearing, and an actual
   logout/login after enabling startup from Applications.
4. Product → Archive with the Release configuration for Any Mac. In Organizer,
   validate and distribute to App Store Connect using App Store distribution.
   Ad-hoc local builds cannot be uploaded as App Store releases.
5. Supply screenshots of the actual app with non-sensitive sample content at an
   [accepted Mac screenshot size](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications).
   Complete age-rating and content-rights answers accurately, use the privacy policy
   above, choose Data Not Collected, set the download price to Free, and add support
   and review contact details belonging to the owner.
6. Select the processed build, review the listing, and submit to App Review.

Free downloads still require [Apple Developer Program membership](https://developer.apple.com/programs/),
normally US$99 annually or the local equivalent. Acceptance depends on Apple's review.
See [App Sandbox](https://developer.apple.com/documentation/xcode/configuring-the-macos-app-sandbox),
[login items](https://developer.apple.com/documentation/servicemanagement/smappservice/register()),
and [privacy manifest requirements](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api).
