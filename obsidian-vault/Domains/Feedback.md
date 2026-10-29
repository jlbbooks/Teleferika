---
tags:
  - domain
  - ui
---

# Feedback

In-app feedback for TeleferiKa (GitHub issue [#25](https://github.com/jlbbooks/Teleferika/issues/25)).

## Current behaviour

- Entry: Settings → **Send feedback** → [`FeedbackScreen`](teleferika.app/lib/ui/screens/feedback/feedback_screen.dart)
- Delivery: opens the device mail app with a prefilled `mailto:` to `AppConfig.feedbackEmail` (`info@jlbbooks.it`)
- Body includes the user message, app version, and optional reply email
- User must tap **Send** in their mail client — the app cannot deliver mail silently without a backend

## Future (when license server is live)

- Add a server endpoint (e.g. `POST /feedback`) that emails `info@jlbbooks.it` server-side
- Switch the app to HTTP submit with `mailto:` kept as fallback when no mail client / offline
- Do **not** embed SMTP credentials in the mobile app

## Related

- [[UI Screens]] · [[Current Features]] · [[licence_server]]
- Config: `AppConfig.feedbackEmail` in `teleferika.app/lib/core/app_config.dart`
