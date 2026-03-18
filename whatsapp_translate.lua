-- whatsapp_translate.lua

local function getTranslation(text, callback)
  local encoded = hs.http.encodeForQuery(text)
  local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=ru&dt=t&q=" .. encoded
  hs.http.asyncGet(url, nil, function(status, body)
    if status ~= 200 then
      hs.alert.show("Translator: HTTP error " .. tostring(status))
      return
    end
    local data = hs.json.decode(body)
    local result = ""
    if data and data[1] then
      for _, part in ipairs(data[1]) do
        if part[1] then result = result .. part[1] end
      end
    end
    if result == "" then
      hs.alert.show("Translator: empty result from API")
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

  getTranslation(text, function(translated)
    local prevClipboard = hs.pasteboard.getContents()
    hs.pasteboard.setContents(translated)

    hs.eventtap.keyStroke({"cmd"}, "a")
    hs.timer.doAfter(0.05, function()
      hs.eventtap.keyStroke({"cmd"}, "v")
      hs.timer.doAfter(0.1, function()
        hs.eventtap.keyStroke({}, "return")
        hs.timer.doAfter(0.3, function()
          hs.pasteboard.setContents(prevClipboard or "")
        end)
      end)
    end)
  end)
end

hs.hotkey.bind({"cmd", "shift"}, "return", translateAndSend)
hs.alert.show("WhatsApp Translator loaded ✓")
