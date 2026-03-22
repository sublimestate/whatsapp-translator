# WhatsApp Russian Translator

Hammerspoon script that intercepts `Cmd+Shift+Return` in WhatsApp on macOS, translates the typed English text to casual Russian via Groq (Llama 3.3 70B), and sends the message. Falls back to Google Translate if Groq is unavailable.

## Files

- `init.lua` — Hammerspoon entry point, just requires `whatsapp_translate`
- `whatsapp_translate.lua` — all logic: hotkey binding, AX element reading, translation API call, clipboard-based text replacement

## Setup

1. Get a free API key from [console.groq.com](https://console.groq.com)
2. Create `~/.hammerspoon/translator_config.lua`:
   ```lua
   return { api_key = "gsk_..." }
   ```
3. This file is gitignored — never commit it

## How It Works

1. Hotkey fires → grab focused AX element via `hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")`
2. Read `AXValue` to get the typed text
3. POST to Groq API (`llama-3.3-70b-versatile`) with a system prompt for casual Russian texting style
4. Parse 3 translation options from `response.choices[1].message.content`
5. Show `hs.chooser` picker — user selects preferred translation
6. Save clipboard, set clipboard to translation, `Cmd+A` → `Cmd+V`, restore clipboard
7. On any Groq error, falls back to Google Translate (direct paste, no chooser)

## Deployment

Files live at `~/.hammerspoon/`. After editing, reload via Hammerspoon menubar → **Reload Config**.

## Known Gotchas

- `hs.axuielement.focusedElement()` does not exist — use `hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")` instead
- `hs.eventtap.keyStrokes()` is unreliable for Cyrillic — use clipboard paste (`Cmd+V`) instead
- App name check via `hs.application.frontmostApplication():name()` is unreliable when a hotkey fires — skip it
- Hammerspoon must have Accessibility permission; if it misbehaves after granting, toggle the permission off/on and relaunch, or run `tccutil reset Accessibility org.hammerspoon.Hammerspoon`
