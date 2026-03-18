# WhatsApp Russian Translator

Hammerspoon script that intercepts `Cmd+Shift+Return` in WhatsApp on macOS, translates the typed English text to Russian via Google Translate's free endpoint, and sends the message.

## Files

- `init.lua` — Hammerspoon entry point, just requires `whatsapp_translate`
- `whatsapp_translate.lua` — all logic: hotkey binding, AX element reading, translation API call, clipboard-based text replacement

## How It Works

1. Hotkey fires → grab focused AX element via `hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")`
2. Read `AXValue` to get the typed text
3. HTTP GET to `translate.googleapis.com` (no API key needed)
4. Assemble translated string from `response[0][i][0]` parts
5. Save clipboard, set clipboard to translation, `Cmd+A` → `Cmd+V` → `Return`, restore clipboard

## Deployment

Files live at `~/.hammerspoon/`. After editing, reload via Hammerspoon menubar → **Reload Config**.

## Known Gotchas

- `hs.axuielement.focusedElement()` does not exist — use `hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")` instead
- `hs.eventtap.keyStrokes()` is unreliable for Cyrillic — use clipboard paste (`Cmd+V`) instead
- App name check via `hs.application.frontmostApplication():name()` is unreliable when a hotkey fires — skip it
- Hammerspoon must have Accessibility permission; if it misbehaves after granting, toggle the permission off/on and relaunch, or run `tccutil reset Accessibility org.hammerspoon.Hammerspoon`
