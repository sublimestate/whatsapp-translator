# Handoff: WhatsApp Russian Translator via Hammerspoon

## Goal

Build a Hammerspoon script that lets the user type English in WhatsApp on macOS, press a hotkey, and have the text automatically translated to Russian and sent — without leaving WhatsApp.

## User Flow

1. User opens WhatsApp on macOS
2. Types a message in English in the chat input field
3. Presses `Cmd+Shift+Return` (instead of normal Enter)
4. The script:
   - Grabs the English text from WhatsApp's input field
   - Sends it to a translation API (Google Translate free endpoint)
   - Replaces the input field text with the Russian translation
   - Sends the message (simulates Enter key)

## Technical Details

### Hammerspoon

- Config file: `~/.hammerspoon/init.lua`
- Reload config: `Cmd+Shift+R` (or via menubar icon)
- Docs: https://www.hammerspoon.org/docs/

### WhatsApp on macOS

- WhatsApp desktop is an Electron app
- Its input fields are accessible via macOS Accessibility API (AXUIElement)
- Use `hs.axuielement` to find and manipulate the focused text field

### Translation API

Use Google Translate's unofficial free endpoint (no API key needed):

```
GET https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=ru&dt=t&q=ENCODED_TEXT
```

Response is a nested JSON array. The translated text is assembled from `response[0][i][0]` for all `i`.

Example response for "Hello, how are you?":
```json
[[["Привет, как дела?","Hello, how are you?",null,null,10]],null,"en"]
```

### Implementation Outline

```lua
-- ~/.hammerspoon/init.lua

local function getTranslation(text, callback)
  local encoded = hs.http.encodeForQuery(text)
  local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=ru&dt=t&q=" .. encoded
  hs.http.asyncGet(url, nil, function(status, body)
    if status == 200 then
      local data = hs.json.decode(body)
      local result = ""
      if data and data[1] then
        for _, part in ipairs(data[1]) do
          if part[1] then result = result .. part[1] end
        end
      end
      callback(result)
    end
  end)
end

local function translateAndSend()
  local app = hs.application.frontmostApplication()
  if app:name() ~= "WhatsApp" then return end

  -- Get focused AX element (the text input field)
  local element = hs.axuielement.focusedElement()
  if not element then return end

  local text = element:attributeValue("AXValue")
  if not text or text == "" then return end

  -- Select all and delete (clear field while translating)
  -- Then replace with translated text and send

  getTranslation(text, function(translated)
    if translated and translated ~= "" then
      -- Set the value of the text field
      element:setAttributeValue("AXValue", translated)
      -- Simulate Enter to send
      hs.eventtap.keyStroke({}, "return")
    end
  end)
end

hs.hotkey.bind({"cmd", "shift"}, "return", translateAndSend)
```

> Note: `hs.axuielement.focusedElement()` may need to be accessed differently depending on Hammerspoon version. Also, setting `AXValue` directly might not work for all Electron apps — an alternative is to select all (`Cmd+A`), then type the translated text via `hs.eventtap.keyStrokes()`.

### Fallback for Setting Text

If `setAttributeValue("AXValue", ...)` doesn't work in WhatsApp (Electron), use this approach instead:

```lua
-- Clear the field
hs.eventtap.keyStroke({"cmd"}, "a")
-- Type translated text
hs.eventtap.keyStrokes(translated)
-- Send
hs.eventtap.keyStroke({}, "return")
```

## Prerequisites

- Hammerspoon installed: `brew install --cask hammerspoon`
- Hammerspoon granted Accessibility permissions in System Settings > Privacy & Security > Accessibility

## Deliverable

A single `~/.hammerspoon/init.lua` file (or a modular `~/.hammerspoon/whatsapp_translate.lua` that gets required from `init.lua`) that implements the above.

Test by:
1. Opening WhatsApp
2. Typing "Hello, how are you?" in a chat
3. Pressing `Cmd+Shift+Return`
4. Verifying "Привет, как дела?" is sent
