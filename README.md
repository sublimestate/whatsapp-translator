# WhatsApp Russian Translator

A [Hammerspoon](https://www.hammerspoon.org/) script for macOS that translates typed English text into natural, casual Russian texting style directly inside WhatsApp using Groq and the Qwen 3.8 27B model.

Press `Cmd + Shift + Return` in any WhatsApp chat, pick from 3 contextual Russian translations, and the message is instantly translated and ready to send. If Groq is ever unreachable, it automatically falls back to Google Translate.

---

## Features

- **Casual Texting Tone**: Translates English into authentic, informal Russian chat slang rather than stiff, literal dictionary translations.
- **3 Translation Choices**: Presents a quick popup chooser with 3 phrasing options to match the exact nuance you want.
- **Ultra-Fast Latency**: Uses Groq's low-latency inference (`qwen/qwen3.8-27b`) for near-instant responses (~50–70ms).
- **In-Place Replacement**: Grabs text directly from the focused input field using macOS Accessibility APIs and replaces it via clipboard paste.
- **Reliable Fallback**: Automatically falls back to Google Translate if the LLM endpoint encounters an issue.

---

## Prerequisites

1. **macOS** with WhatsApp Desktop installed.
2. **Hammerspoon**: Install via Homebrew if you don't have it:
   ```bash
   brew install --cask hammerspoon
   ```
3. **Accessibility Permissions**: Hammerspoon requires Accessibility access to read and replace text:
   - Open **System Settings → Privacy & Security → Accessibility**.
   - Ensure **Hammerspoon** is enabled.
4. **Groq API Key**: Get a free API key at [console.groq.com](https://console.groq.com).

---

## Installation & Setup

1. **Clone this repository** (or copy the files) into your Hammerspoon directory:
   ```bash
   git clone https://github.com/sublimestate/whatsapp-translator.git ~/dev_env/whatsapp-translator
   cp ~/dev_env/whatsapp-translator/whatsapp_translate.lua ~/.hammerspoon/
   ```

2. **Configure `~/.hammerspoon/init.lua`**:
   Ensure `init.lua` loads the script:
   ```lua
   require("whatsapp_translate")
   ```

3. **Set up your API key**:
   Create `~/.hammerspoon/translator_config.lua` (you can reference `translator_config.lua.example`):
   ```lua
   return {
     api_key = "gsk_your_groq_api_key_here"
   }
   ```
   > **Note**: `translator_config.lua` contains your private API key and is ignored by git. Never commit it to a repository.

4. **Reload Hammerspoon**:
   Click the Hammerspoon menu bar icon and select **Reload Config** (or press `Cmd + Shift + R`). You should see a notification: `WhatsApp Translator loaded ✓`.

---

## Usage

1. Open WhatsApp on macOS and open any chat.
2. Type an English message in the message input field (e.g. `what are you doing tonight?`).
3. Press **`Cmd + Shift + Return`**.
4. A chooser overlay will appear with 3 Russian translation options.
5. Select your preferred translation with the arrow keys or mouse and hit `Return`.
6. The text in WhatsApp will be replaced with the chosen translation.

---

## Troubleshooting

- **No response when pressing hotkey**: Check that Hammerspoon has Accessibility permissions. If macOS updated recently, toggle the permission off and on in **System Settings → Privacy & Security → Accessibility**, then restart Hammerspoon.
- **Groq Error fallback**: If you see a notification that Groq failed and it fell back to Google Translate, verify that your API key in `~/.hammerspoon/translator_config.lua` is valid and active.
- **Hammerspoon Logs**: Open the Hammerspoon Console from the menu bar to view error logs and diagnostics.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
