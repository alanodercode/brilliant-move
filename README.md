# brilliant-move

I've been vibecoding so much that I forgot to manifest. So I built a Claude Code mod that gives me a TikTok as a little treat whenever I have a genuinely good idea.

Claude judges your ideas like a chess engine judges moves. Most of them are fine. Now and then one is a **!! Brilliant Move**: then your reply opens with one line on why, and one of your edits fades in over the terminal, plays once and fades out.

It's stingy on purpose. The fun part is the half-second where you wonder: *was that one brilliant?*

It won't get you more revenue. But if you're as brainrotted as I am, it's a great way to keep the vibes up in your home office, especially on a Bluetooth speaker.

## Install

In Claude Code, type:

```
/plugin install brilliant-move --marketplace alanodercode/brilliant-move
```

Answer `y` to add the marketplace, then press Enter to install for your user.

## Add your edits

**From your iPhone (easiest):** in the Photos app, make an album called **Brilliant Moves** and save your favorite edits to it. With iCloud Photos on, the mod copies new videos from that album every time you start Claude Code. The first time, macOS asks whether Terminal may access your photos: allow it. The album is only read, never changed.

**Or by hand:** drop `.mp4` / `.mov` files into **`~/Movies/Brilliant Moves`** (created on first start).

Square edits look best; other formats get black bars. Edits over 60 seconds are skipped from the album.

The first time Claude hands out a brilliant move, Claude Code asks whether it may use the `brilliant_move` tool. Pick **"Yes, and don't ask again"** so the next one is a surprise.

## How it works

- **Who decides:** Claude, through one tool. It may only call it for *your* idea when it's a non-obvious insight, a reframe that makes the problem smaller, or leverage that removes whole chunks of work. Never for routine requests or its own work. About one in ten ideas at most.
- **The player:** a small native macOS window (`player/edit-player.swift`; `player/build.sh` rebuilds both binaries from source, prebuilt for Apple Silicon and Intel). It sits centered over your Terminal or iTerm2 window, lets clicks pass through and never takes keyboard focus, so you keep typing.
- **Requirements:** macOS 13 or newer, and Claude Code with mod support.

## Uninstall

```
/plugin uninstall brilliant-move
```

Your edits stay in `~/Movies/Brilliant Moves`.
