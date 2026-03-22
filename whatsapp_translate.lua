-- whatsapp_translate.lua

local configPath = os.getenv("HOME") .. "/.hammerspoon/gemini_config.lua"
local ok, config = pcall(dofile, configPath)
if not ok or not config or not config.api_key then
  hs.alert.show("Translator: missing ~/.hammerspoon/gemini_config.lua with api_key")
  return
end

local function pasteText(app, text)
  local prevClipboard = hs.pasteboard.getContents()
  hs.pasteboard.setContents(text)
  hs.timer.doAfter(0.3, function()
    app:activate()
    hs.timer.doAfter(0.15, function()
      hs.eventtap.keyStroke({"cmd"}, "a")
      hs.timer.doAfter(0.05, function()
        hs.eventtap.keyStroke({"cmd"}, "v")
        hs.timer.doAfter(0.1, function()
          hs.pasteboard.setContents(prevClipboard or "")
        end)
      end)
    end)
  end)
end

local function getTranslation(text, callback)
  local encoded = hs.http.encodeForQuery(text)
  local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=ru&dt=t&q=" .. encoded

  hs.http.asyncGet(url, nil, function(status, body)
    if status ~= 200 then
      hs.alert.show("Translator: HTTP error " .. tostring(status))
      return
    end
    local data = hs.json.decode(body)
    if not data or not data[1] then
      hs.alert.show("Translator: unexpected API response")
      return
    end
    local parts = {}
    for _, segment in ipairs(data[1]) do
      if segment[1] then
        parts[#parts + 1] = segment[1]
      end
    end
    local result = table.concat(parts)
    if result == "" then
      hs.alert.show("Translator: empty result")
      return
    end
    callback(result)
  end)
end

local function translateAndSend()
  local element = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
  if not element then
    hs.alert.show("Translator: no focused element")
    return
  end

  local text = element:attributeValue("AXValue")
  if not text or text == "" then
    hs.alert.show("Translator: input field is empty")
    return
  end

  local app = hs.application.frontmostApplication()

  getTranslation(text, function(translated)
    pasteText(app, translated)
  end)
end

hs.hotkey.bind({"cmd", "shift"}, "return", translateAndSend)
hs.alert.show("WhatsApp Translator loaded ✓")
