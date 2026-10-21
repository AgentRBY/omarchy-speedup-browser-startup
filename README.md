# Speedup Browser Startup

An [Omarchy](https://omarchy.org) shell plugin that keeps your default Chromium-based browser running with no windows, so new windows and links open almost instantly. It is the Linux counterpart of Edge's Startup Boost on Windows, which Linux builds don't ship.

**The trade-off is memory**: the browser stays resident even with every window closed, about 0.5–0.8 GB. It also shows a tray icon, which you can hide from Omarchy's tray drawer.

| Opening a browser window | Time to window | Time saved | Speedup |
|---|---|---|---|
| Fresh browser start | ~0.5 s | — | — |
| With Speedup Browser Startup | ~0.08 s | 84% | 6.3× |
| First window after all were closed (restores your session) | ~0.14 s | 72% | 3.6× |

Measured with Microsoft Edge 155 on a Ryzen 7 5800X, from `omarchy-launch-browser` to the window being mapped in Hyprland.

## How it works

- When omarchy-shell loads the plugin, it starts your default browser as a systemd user unit, `speedup-browser-startup`, with `--no-startup-window --keep-alive-for-test`. The unit runs in `app-graphical.slice`, like apps started with `uwsm-app`.
- On its own, `--no-startup-window` doesn't keep Chromium alive: the browser shuts down once extensions have loaded unless a background app holds it. `--keep-alive-for-test` is the holder that needs no app. Chromium's own tests use it to keep the browser alive with no windows.
- Omarchy's launcher already hands new windows and links to a running browser over its singleton socket, so they open in the process that is already warm.
- Every 60 seconds the plugin checks two things. It restarts the background browser only if one of them is true **and** the browser owns no windows (web app windows included):
  - the browser was upgraded (its binary on disk was replaced);
  - your default browser changed.
- It never restarts while pacman holds its lock.

Session restore ("Continue where you left off") keeps working. Tabs come back with the first window, and again after you close every window.

## Requirements

- Omarchy 4.5 or newer.
- One of these as the default browser:

| Browser | Supported | Window time |
|---|---|---|
| Chromium | yes | ~0.08 s |
| Google Chrome | yes | ~0.08 s |
| Brave | yes | ~0.08 s |
| Brave Origin | yes | ~0.08 s |
| Microsoft Edge | yes | ~0.08 s |
| Vivaldi | yes | ~0.15 s |

  Vivaldi works but is slower, because Omarchy's launcher has no fast hand-off for it.

Tested on Microsoft Edge and Chromium. Firefox, Zen and Flatpak browsers are not supported: the plugin does nothing for them.

## Dependencies

Nothing to install beyond Omarchy itself. The plugin uses:

- `bash` and `jq`.
- A systemd user session (`systemd-run --user`) and Hyprland's `hyprctl`.
- Omarchy's `omarchy-cmd-default-browser` and its browser launcher hand-off.

## Install

```sh
omarchy plugin add https://github.com/AgentRBY/omarchy-speedup-browser-startup --enable
```

## Remove

```sh
omarchy plugin remove io.github.agentrby.omarchy-speedup-browser-startup
```

- **No browser windows open:** the background browser stops right away.
- **Windows open:** the browser keeps running until you log out. To stop it now, run `systemctl --user stop speedup-browser-startup`.

The plugin leaves behind only your optional `~/.config/speedup-browser-startup-flags.conf`. Its runtime copy in `$XDG_RUNTIME_DIR` is cleared at logout.

## Usage

The plugin needs no setup. To inspect or control the background browser by hand:

```sh
bash "$XDG_RUNTIME_DIR/speedup-browser-startup/bin/speedup-browser-startup" status   # running pid, open windows
bash "$XDG_RUNTIME_DIR/speedup-browser-startup/bin/speedup-browser-startup" stop
bash "$XDG_RUNTIME_DIR/speedup-browser-startup/bin/speedup-browser-startup" start
```

### Extra flags

The background browser reads your regular flags file, for example `~/.config/microsoft-edge-stable-flags.conf`.

Omarchy's fast hand-off only accepts the flags Omarchy ships there. Any other flag makes every new window start a second browser process (~0.15 s). Put such flags in `~/.config/speedup-browser-startup-flags.conf` instead, one or more per line, `#` for comments:

```
--disable-features=ElasticOverscroll
```

([omacom/omarchy#16185](https://github.com/omacom/omarchy/pull/16185) proposes letting `--disable-features` through.)

## Things to know

- **Memory.** The browser stays resident: about 0.5–0.8 GB, with your extensions running in the background.
- **Tray icon.** Chromium shows a tray icon while it runs in the background. Hide it from Omarchy's tray drawer with **Hide**.
- **Exit ends it.** Exit from the browser menu or the tray icon stops the background browser until the shell loads the plugin again, which happens at your next login.
- **Unsupported switch.** `--keep-alive-for-test` is an undocumented Chromium switch. It has existed since 2010, but a future Chromium could change or remove it.
- **Disabling or removing the plugin.**
  - If the browser has no windows, it stops.
  - If windows are open, it keeps running until you log out.
  - Restarting the shell never stops it.
- **If your browser is already running** when the plugin loads, the plugin leaves it alone. The speedup starts at the next login.

## License

MIT
