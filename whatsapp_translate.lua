-- whatsapp_translate.lua

local configPath = os.getenv("HOME") .. "/.hammerspoon/translator_config.lua"
local ok, config = pcall(dofile, configPath)
if not ok or not config or not config.api_key then
  hs.alert.show("Translator: missing ~/.hammerspoon/translator_config.lua with api_key")
  return
end

local SYSTEM_PROMPT = [[You are a casual Russian texter. Translate the following English text to Russian as if you're texting a friend on WhatsApp. Rules:
- Use lowercase unless it's a name or start of a new message
- Be informal and natural, not literary or formal
- Use common texting abbreviations where natural
- Don't over-translate idioms — adapt them naturally
- Keep the same tone and energy as the original
- Only use commas if the original English text contains commas — otherwise omit them entirely
- Provide exactly 3 different translation options
- Format as numbered lines: 1. ... 2. ... 3. ...
- Output ONLY the 3 numbered translations, nothing else]]

local function parseOptions(text)
  local options = {}
  for line in text:gmatch("[^\r\n]+") do
    local option = line:match("^%d+%.%s*(.+)")
    if option then
      options[#options + 1] = option
    end
  end
  return options
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

local function getGoogleTranslation(text, callback)
  local encoded = hs.http.encodeForQuery(text)
  local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=ru&dt=t&q=" .. encoded

  hs.http.asyncGet(url, nil, function(status, body)
    if status ~= 200 then
      hs.alert.show("Translator: fallback also failed (HTTP " .. tostring(status) .. ")")
      return
    end
    local data = hs.json.decode(body)
    if not data or not data[1] then
      hs.alert.show("Translator: fallback returned unexpected response")
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
      hs.alert.show("Translator: fallback returned empty result")
      return
    end
    callback(result)
  end)
end

local function getTranslation(text, callback, fallbackCallback)
  local url = "https://api.groq.com/openai/v1/chat/completions"

  local requestBody = hs.json.encode({
    model = "qwen/qwen3.8-27b",
    messages = {
      { role = "system", content = SYSTEM_PROMPT },
      { role = "user", content = text },
    },
    temperature = 0.3,
    max_tokens = 512,
  })

  local headers = {
    ["Content-Type"] = "application/json",
    ["Authorization"] = "Bearer " .. config.api_key,
  }

  hs.http.asyncPost(url, requestBody, headers, function(status, body)
    if status ~= 200 then
      hs.alert.show("Translator: Groq error " .. tostring(status) .. ", falling back to Google Translate")
      fallbackCallback()
      return
    end
    local data = hs.json.decode(body)
    if not data or not data.choices or not data.choices[1] then
      hs.alert.show("Translator: unexpected Groq response, falling back")
      fallbackCallback()
      return
    end
    local result = data.choices[1].message.content
    if not result or result == "" then
      hs.alert.show("Translator: empty Groq result, falling back")
      fallbackCallback()
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

  local function doGoogleFallback()
    getGoogleTranslation(text, function(translated)
      pasteText(app, translated)
    end)
  end

  getTranslation(text, function(raw)
    local options = parseOptions(raw)
    if #options == 0 then
      hs.alert.show("Translator: could not parse options, falling back")
      doGoogleFallback()
      return
    end

    local chooserItems = {}
    for i, opt in ipairs(options) do
      chooserItems[i] = { text = opt }
    end

    local chooser = hs.chooser.new(function(selected)
      if not selected then return end
      pasteText(app, selected.text)
    end)
    chooser:choices(chooserItems)
    chooser:placeholderText("Pick a translation")
    chooser:show()
  end, doGoogleFallback)
end

hs.hotkey.bind({"cmd", "shift"}, "return", translateAndSend)
hs.alert.show("WhatsApp Translator loaded ✓")
