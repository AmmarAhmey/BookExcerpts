# BookExcerpts

**Turn any highlighted passage in [KOReader](https://github.com/koreader/koreader) into a clean, shareable image, with your book's cover, title, author and chapter, in several layouts and colour themes. Then send it to your phone over Wi-Fi.**



| BookExcerpt Option in Menu | Default Share Card |
| :---: | :---: |
| ![](assets/images/BookExcerpt%20Options%20in%20KOreader%20Highligh%20Menu.png) | ![](assets/images/Default%20Card.png) |
| **Default Card Dark** | **Highlight Card Design** |
| ![](assets/images/Default%20Dark%20Theme%20Card.png) | ![](assets/images/Highlight%20Card%20Design.png) |
| **Highlight Card Sepia** | **Change Theme Color** |
| ![](assets/images/Highlight%20Card%20Sepia%20Theme.png) | ![](assets/images/Changing%20Card%20Theme.png) |
| **Change Card Layout Design** | |
| ![](assets/images/Changing%20Card%20Layout%20and%20Design.png) | |


 

---

## Table of contents

1. [Introduction](#introduction)
2. [Why I made it](#why-i-made-it)
3. [Features](#features)
4. [How it works](#how-it-works)
5. [Installation](#installation)
6. [Usage](#usage)
7. [Layouts and themes](#layouts-and-themes)
8. [Sending the image to your phone](#sending-the-image-to-your-phone)
9. [Project structure](#project-structure)
10. [Extending the plugin](#extending-the-plugin)
11. [Troubleshooting](#troubleshooting)
12. [Compatibility and known limitations](#compatibility-and-known-limitations)
13. [Contributing](#contributing)
14. [License](#license)

---

## Introduction

BookExcerpts adds a **Share excerpt** button to KOReader's highlight popup. Select some text, tap the button, and the plugin draws the passage as a PNG image:

- the quote, set in the font you are currently reading with,
- the book's cover, title, author and the current chapter name,
- a rounded, bordered card in the colours of your choice.

A preview opens straight away, where you can keep the image, delete it, switch to another layout or theme, or send it to your phone with a QR code.

## Why I made it

I read on an e-ink Kindle (a Kindle Colorsoft) running KOReader, and I often wanted to share a passage I'd just highlighted. KOReader lets you highlight and export text, but I couldn't find a simple way to turn a highlight into a good-looking image that carries the book's details with it.

Getting the image off the device was the second problem. The Kindle's Bluetooth is for audio devices only, so file transfer over Bluetooth isn't an option. Device-discovery tools such as LocalSend didn't work reliably on my home Wi-Fi. So the plugin also includes a tiny, temporary web server: it shows a QR code, you scan it with your phone, and the image opens in your browser. It doesn't depend on any discovery.

## Features

- **One-tap excerpt images** from the highlight popup. The image has a fixed width (900 px) and a height that grows with the length of the quote.
- **Uses your book's font** for the quote, so the image looks like the page you were reading.
- **Cover, title, author and chapter** are read automatically from the book. If a book has no cover, a placeholder with the title's first letter is drawn.
- **Two layouts**
  - *Card*: the quote on top, a divider, then cover and details in a rounded bordered card.
  - *Highlight*: title, "by Author", chapter, then the excerpt as an italic quote with a vertical bar and a "shared on" line at the end. The title is on a single line at a fixed size.
- **Five themes**: *Auto (match device)*, *Classic*, *Dark*, *Sepia* and *Midnight blue*. Any theme works with any layout.
- **Auto theme**: follows KOReader's night mode. Dark card in night mode, light card otherwise.
- **Preview screen** with *Keep*, *Layout*, *Theme*, *Delete* and *Send to phone* buttons. Changing layout or theme re-renders just that image.
- **Preferences in the menu**: choose a preferred layout and theme once, under *Tools → More tools → BookExcerpts*.
- **Send to phone over Wi-Fi** with a QR code and a built-in one-file web server. No app needed on the phone.
- **Wi-Fi handling**: if Wi-Fi was off, the plugin turns it on when you send, and switches it off again when you close the preview.
- **Modular and extensible**: new themes and layouts are single files added to a list. See [Extending the plugin](#extending-the-plugin).

## How it works

1. **Hook.** On start-up the plugin registers a button in KOReader's highlight dialog and an entry in the *More tools* menu.
2. **Collect.** When you tap *Share excerpt*, the selected text is cleaned (whitespace collapsed) and the book's title, author, current chapter and cover are read.
3. **Choose.** The plugin picks your preferred layout and theme. A theme is only a colour palette; *Auto* resolves to *Dark* in night mode and *Classic* otherwise.
4. **Render.** The layout builds a tree of KOReader widgets (text boxes, containers, images), which is painted into an off-screen buffer. The buffer is saved as a PNG in `<koreader data folder>/excerpts/`.
5. **Preview.** The PNG is shown full screen with the action buttons.
6. **Optional: send.** *Send to phone* turns Wi-Fi on if needed, finds the device's IP address, starts a small HTTP server for that one image, and shows a QR code of `http://<ip>:<port>/`.
7. **Clean up.** Closing the preview stops the server and, if the plugin had turned Wi-Fi on, turns it off again.

```
highlight ─► Renderer ─► layout.build(ctx, theme.palette) ─► PNG ─► Preview ─► Keep / Delete / Send
                │
                └─ ctx = text, book info, cover, width, fonts
```

## Installation

### Requirements

- KOReader installed and working on your device. On a Kindle this means the device must be jailbroken first. The guide at [kindlemodding.org](https://kindlemodding.org/jailbreaking/post-jailbreak/koreader.html) walks through it.
- For *Send to phone*: Wi-Fi, and a phone on the same network (or the device connected to your phone's hotspot).

### Steps

1. Download the latest release (or this repository as a ZIP) and unzip it. You should have a folder called **`bookexcerpts.koplugin`** with `main.lua` and `_meta.lua` directly inside it, plus a `bookexcerpts/` subfolder.
2. Copy the whole `bookexcerpts.koplugin` folder into KOReader's `plugins` folder:

   | Device | Plugins folder |
   |---|---|
   | Kindle | `koreader/plugins/` |
   | Kobo | `.adds/koreader/plugins/` |
   | Android | `plugins/` inside the KOReader folder |

3. **Fully restart KOReader.**
4. Open any book and check that the plugin loaded: *Tools (gear icon) → More tools → BookExcerpts*.

## Usage

1. In a book, long-press a word and drag to select a passage.
2. In the popup, tap **Share excerpt**.
3. The preview opens:

   | Button | What it does |
   |---|---|
   | **Keep** | Close the preview and keep the image. (The Back key does the same.) |
   | **Layout** | Choose a different layout for this image. |
   | **Theme** | Choose a different theme for this image. |
   | **Delete** | Delete the image and close the preview. |
   | **Send to phone (Wi-Fi)** | Start the temporary web server and show a QR code. |

4. Images are saved as `excerpt_<date>_<time>_<layout>_<theme>.png` in the `excerpts` folder inside KOReader's data folder (on a Kindle, usually `koreader/excerpts/`).

### Setting your preferences

*Tools → More tools → BookExcerpts*

- **Preferred layout**: used for every new excerpt (default: *Card*).
- **Preferred theme**: used for every new excerpt (default: *Auto (match device)*).

The *Layout* and *Theme* buttons in the preview change only the image you are looking at.

## Layouts and themes

A **layout** decides how the excerpt is arranged. A **theme** decides the colours. They are independent, so every layout works with every theme.

### Layouts

| Layout | Description |
|---|---|
| **Card** (default) | Quote at the top, divider, then the cover on the left with title, author and chapter on its right, all inside a rounded card. The quote and title are size 26 and the details block is compact. |
| **Highlight** | Title on one line at a fixed size, then "by Author", the chapter, the italic quote with a vertical bar, and "— shared on *date*" at the end, inside a thin frame. |

### Themes

| Theme | Description |
|---|---|
| **Auto (match device)** (default) | *Dark* when KOReader is in night mode, *Classic* otherwise. |
| **Classic** | Black on white. |
| **Dark** | Light text on a near-black card. |
| **Sepia** | Warm paper tones. |
| **Midnight blue** | Dark blue with an amber accent. |

> A PNG saved here has no transparency, so the area outside the rounded corners is filled with the theme's `outer` colour (white for light themes, near-black for dark themes).

## Sending the image to your phone

The *Send to phone (Wi-Fi)* button:

1. turns Wi-Fi on if it is off and waits for a connection,
2. finds the device's IP address (retrying for a few seconds while the router assigns one),
3. starts a small HTTP server on a free port between 8089 and 8099,
4. shows a QR code for `http://<ip>:<port>/` (or the plain address, if your KOReader has no QR widget).

On your phone, scan the code. A page opens with the image and a **Download image** link.

**Stopping and clean-up.** The server stops when you dismiss the QR screen, when you close the preview, when you change layout or theme, or automatically after 5 minutes. If Wi-Fi was off before you created the excerpt, it is switched off again when you close the preview.

**Privacy note.** The server has no password and serves only that one image. While it is running, anyone on the same network who knows the address could open it. Use it on a network you trust.

**Why not Bluetooth?** On Kindle, Bluetooth is limited to audio devices and there is no file-transfer profile that KOReader plugins can use. Direct Wi-Fi to the device's own address avoids the discovery problems some routers cause with tools like LocalSend.

## Project structure

```
bookexcerpts.koplugin/
├── _meta.lua                  Plugin name and description (read by KOReader)
├── main.lua                   Entry point: highlight button, menu, share flow
└── bookexcerpts/
    ├── settings.lua           Saved settings (preferred layout and theme)
    ├── layouts.lua            Layout registry (list of layouts, first = default)
    ├── layouts/
    │   ├── card.lua           "Card" layout
    │   ├── highlight.lua      "Highlight" layout
    │   └── _template.lua      Template for a new layout (not loaded)
    ├── themes.lua             Theme registry (list of themes, "auto" logic)
    ├── themes/
    │   ├── classic.lua        Palettes, one file each
    │   ├── dark.lua
    │   ├── sepia.lua
    │   ├── midnight.lua
    │   └── _template.lua      Template for a new theme (not loaded)
    ├── parts.lua              Reusable building blocks for layouts
    ├── book.lua               Title, author, chapter and cover of the open book
    ├── fonts.lua              The book's current font and KOReader's UI font
    ├── renderer.lua           Layout + theme -> PNG file
    ├── preview.lua            Preview window and its buttons
    ├── picker.lua             The "Layout" / "Theme" selection dialog
    ├── sharing.lua            "Send to phone": Wi-Fi + server orchestration
    ├── webserver.lua          The one-file HTTP server and QR code
    └── wifi.lua               Wi-Fi state helpers and IP lookup
```

Design principles:

- **One job per file.** Rendering, previewing, settings, networking and layout code are separate, so a change in one place doesn't ripple through the others.
- **Registries instead of hard-coded lists.** Layouts and themes are loaded from a list. A broken layout or theme file is logged and skipped; it can't stop the plugin from loading.
- **Layout and theme are separate.** A theme is only data (colours). A layout is code that uses those colours.

## Extending the plugin

### Add a theme (colours only)

1. Copy `bookexcerpts/themes/_template.lua` to `bookexcerpts/themes/ocean.lua` and edit it:

   ```lua
   local _ = require("gettext")

   return {
       key = "ocean",            -- unique id, saved in settings; don't change it later
       name = _("Ocean"),        -- shown in menus
       palette = {
           bg     = "#EAF4F8",   -- card background
           fg     = "#0B2A3C",   -- quote and title
           muted  = "#4F6D7A",   -- author, chapter
           line   = "#1B6A8A",   -- dividers and bars
           border = "#1B6A8A",   -- card border
           outer  = "#FFFFFF",   -- margin around the card
       },
   }
   ```

2. Add `"ocean"` to the `ORDER` list in `bookexcerpts/themes.lua`.

It now appears in the preview's *Theme* button and in *Preferred theme*, for every layout.

### Add a layout

A layout is a table `{ key, name, build }`. `build(ctx, palette)` returns **a widget and a canvas colour**. The widget is drawn on a canvas of its own size.

`ctx` gives you:

| Field | Meaning |
|---|---|
| `ctx.text` | The cleaned-up excerpt |
| `ctx.info` | `{ title, author, chapter }` (strings, may be empty) |
| `ctx.cover_bb` | Cover image buffer, or `nil` if the book has none |
| `ctx.width` | Image width in pixels (900) |
| `ctx.face(size, bold, italic)` | Font face of the book |
| `ctx.uiFace(size, bold)` | KOReader's own sans-serif UI font |

`bookexcerpts/parts.lua` provides ready-made pieces:

| Function | Returns |
|---|---|
| `Parts.colors(palette)` | Palette strings converted to colours |
| `Parts.quote(ctx, colors, width, size, italic)` | The quote text box |
| `Parts.divider(colors, width, thickness)` | A horizontal line |
| `Parts.cover(ctx, colors, h, opts)` | The cover (or placeholder) at height `h` |
| `Parts.meta(ctx, colors, width, max_h, opts)` | Title, author and chapter block |
| `Parts.footer(ctx, colors, width, opts)` | Cover + details, with the cover growing to match the details |

A minimal example, saved as `bookexcerpts/layouts/minimal.lua`:

```lua
local FrameContainer = require("ui/widget/container/framecontainer")
local Parts = require("bookexcerpts/parts")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local _ = require("gettext")

local Minimal = { key = "minimal", name = _("Minimal") }

function Minimal.build(ctx, palette)
    local colors = Parts.colors(palette)
    local pad = 60
    local width = ctx.width - 2 * pad

    local group = VerticalGroup:new{
        align = "left",
        Parts.quote(ctx, colors, width, 26),
        VerticalSpan:new{ width = 24 },
        Parts.divider(colors, width, 2),
        VerticalSpan:new{ width = 24 },
        Parts.footer(ctx, colors, width, {}),
    }
    local frame = FrameContainer:new{
        background = colors.bg, bordersize = 0, padding = pad, margin = 0, group,
    }
    return frame, colors.bg
end

return Minimal
```

Then add `"minimal"` to the `ORDER` list in `bookexcerpts/layouts.lua`. It shows up in the *Layout* button and in *Preferred layout*, and works with every theme.

Tips for layout authors:

- Give every text widget a `bgcolor` that matches the card. KOReader's text widgets default to a white background, which breaks dark themes.
- Pass `original_in_nightmode = false` to any `ImageWidget` you paint into the off-screen buffer. Otherwise KOReader inverts it when the device is in night mode.
- Keep `key` values stable once published; they are stored in users' settings.
- The first entry in a registry's `ORDER` list is the default.

### Other ideas for extension

- **New settings:** add getters and setters in `settings.lua` and use them from `main.lua`. Nothing else needs to touch `G_reader_settings`.
- **New ways to send:** `sharing.lua` is the one place that knows about Wi-Fi and the web server, so another method can live beside it.
- **Possible future features:** a Wi-Fi network chooser in the *Send to phone* step, more layouts, other export formats.

## Troubleshooting

| Problem | What to try |
|---|---|
| Menu entry or button missing | Check the folder is named exactly `bookexcerpts.koplugin` and sits directly in `plugins/`. Restart KOReader fully. Check *Plugin management* for a disabled entry. |
| Two "Share excerpt" buttons | The old `excerptshare.koplugin` folder is still installed. Delete it. |
| "Could not create excerpt" | The message shows the underlying error. Please include it when reporting an issue. |
| Text invisible on a dark theme | Use this version or later: every text widget needs an explicit background colour. |
| "Could not find the Kindle's IP address" | Make sure Wi-Fi is really connected (check the Network info in KOReader). The plugin retries for about 12 seconds. |
| QR code opens nothing on the phone | The phone must be on the same network. Turn off "AP isolation" / "client isolation" on the router, or connect the device to your phone's hotspot. |
| No QR code, only an address | Your KOReader version has no QR widget. Type the address shown into your phone's browser. |
| Wi-Fi stays on after closing | It is only switched off if it was off before you created the excerpt, and only when the preview is closed with *Keep*, *Delete* or Back. |

## Compatibility and known limitations

- Developed and tested on a **Kindle Colorsoft** running KOReader. It uses only standard KOReader APIs, so it should work on other KOReader devices, but I haven't tested them. Wi-Fi switching and the QR widget in particular can differ between devices and KOReader versions. Reports are welcome.
- Font sizes are KOReader units and scale with the device's screen density, so the same size looks different on different devices.
- The image width is fixed at 900 px; only the height varies.
- For PDFs and other fixed-layout documents there is no document font, so a default font is used.
- The chapter name comes from the book's table of contents. Books without one show no chapter line.
- The preview and the *Send to phone* page show the saved PNG; there is no built-in sharing to other apps.

## Contributing

Issues and pull requests are welcome. When reporting a problem, please include your device, KOReader version, and the exact error message shown. New themes and layouts are especially welcome; they're single files (see [Extending the plugin](#extending-the-plugin)).

## License

MIT License 

## Acknowledgements

Built on top of [KOReader](https://github.com/koreader/koreader) and its plugin API.
