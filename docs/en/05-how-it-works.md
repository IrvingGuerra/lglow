# 5. How it works (under the hood)

[Español](../05-como-funciona.md)

For anyone who wants to understand it, adapt it to another model, or contribute.

## Two homes in webOS 4.10

| App | What it is |
| --- | --- |
| `com.webos.app.fullhome` | The full-screen home that opens with the Home key since the December 2023 update (firmware 05.40.09): banner, rows and square apps. `defaultApps.home` points to this one. |
| `com.webos.app.home` | The classic webOS 4.5 bar with tilted tiles. It stays loaded in memory even though it is barely used. |

Both are built in **QML** (plain text), in `/usr/palm/applications/<app>/qml`, inside a read-only, signed
partition. In webOS 10 the home is Flutter; not here.

## Mounting on top, without touching the original

Same as in [webos10-homescreen-customization](https://github.com/mareklarek/webos10-homescreen-customization):

```sh
mount --bind /var/lib/webosbrew/fullhomecustom/qml /usr/palm/applications/com.webos.app.fullhome/qml
```

The mount lives in memory. It disappears on reboot, and `init.d/10-homecustom` sets it up again. If something
goes wrong, just don't mount it.

## The CRIU trick (key on webOS 4)

Mounting the QML **is not enough**: the home is not loaded from the files, it is **restored with CRIU** (checkpoint/restore)
from a factory image that already holds the original QML in memory:

- `/etc/palm/sam-conf-tv.json` → `CRIUSupportApps` includes `com.webos.app.home` and `com.webos.app.fullhome`.
- The images live in `/tmp/checkpoint/<app>` and in `/mnt/lg/cmn_data/checkpoint/<app>`. If you delete the one in
  `/tmp`, the `criu` service copies it back from `cmn_data`. Marking it as `invalid_img` doesn't work either.

What does work: **covering both folders with an empty folder** (another `mount --bind`) and killing the process.
SAM finds no image, launches the home from scratch and reads the mounted QML. This doesn't delete anything either.

## Boot order and timing

- With Quick Start+ off, every power-on is a full boot that resumes from the factory snapshot
  (`/sys/power/mode = resume`).
- The system fires Homebrew Channel's `startup.sh` around **second ~42**, which then runs
  `run-parts /var/lib/webosbrew/init.d`.
- `10-homecustom` runs first and takes under a second: the home is ready around **second ~45**.
- If the home was already on screen at that point, it is relaunched instantly with the new design. The script
  knows this from the fullhome's last `NL_VSC … "visible":true` in `/var/log/messages`.
- `60-sinprecarga` runs afterwards, entirely in the background: right after the TV is turned on, each `luna-send` takes
  several seconds.

## Changes to the home (tv/patches and tv/qml)

| File | Change |
| --- | --- |
| `Configurations/SystemServiceResponseProcessors.js` | Filters `listLaunchPoints` with `HIDDEN_IDS` (hidden apps), including incremental changes. |
| `Interfaces/AppInterfaces/AppInterfaces.qml` | `isDefaultShelf: true`: LG's offline mode, with no content rows from the server. |
| `Model/ShelfList.js` | Keeps only `HOME_SH_TOP` and `HOME_SH_APPS`. |
| `Containers/Main/Hero.qml`, `TopShelf.qml`, `AppInitializer/SystemProperties.qml` | No ad banners, no "Comience una nueva experiencia / Ir a Apps" (Start a new experience / Go to Apps). |
| `Containers/MainView.qml` | Background per theme; app row at the bottom (`appListHomeY`); "Para ti" (For you); scroll down to all apps (`appsScroll`); LGlow's buttons and menu (LG's icon row is hidden); focus chain. |
| `GlobalStyle.qml`, `LaunchPoint.qml`, `AppTile.qml`, `TopGlobalAction.qml` | Borderless 5:3 tiles, dark top icons. |
| **New:** `AppGrid.qml`, `ParaTi.qml`, `AllAppsPage.qml` | The app row (`pinned` and `all` modes), the header with trending content and the bottom part with all apps. |
| **New:** `LglowTema.qml`, `LglowBarra.qml`, `LglowMenu.qml`, `LglowPanel.qml` | The theme (light, dark or automatic, saved with LocalStorage), the top buttons (theme and gear), the theme menu and the quick panel (picture and sound via `settingsservice/setSystemSettings`, sleep timer via `tv.time/setSleepTimeInfo`, inputs via `eim/getAllInputStatus`). |

LG's original row (`MainRibbon`) stays loaded, invisible, because a lot of the home's code depends on it.
In edit mode (pencil), LG's row is shown.

### Details that took some work

- **Focus when returning from an app.** `MainView` has `visible: isAppForeground`: when an app opens, the whole home
  becomes invisible and loses focus. `AppGrid.claimFocus()` takes it back when it becomes visible again, and also
  when the preloadmanager preloads the home in the background.
- **Back.** The compositor only passes the key to the home if its window has
  `_WEBOS_ACCESS_POLICY_KEYS_BACK = "true"`. On top of that, LG closes the home on **release** of Back
  (`UIController.Keys.onReleased → goBack`). That's why the all-apps part goes back on release: if it closed on
  press, the release would reach LG and trigger a second "back".
- **Navigation in `GridView`.** With `interactive: false`, in Qt 5.6 the `GridView` ignores the arrow keys; they are
  handled manually.
- **Remote's Home key** = `Qt.Key_Super_L` (evdev `KEY_LEFTMETA`, 125). The compositor does
  `applicationManager.launch(defaultApp, {"launchType": "homeKey"})`.

## The settings panel and the loading screen (the compositor)

The remote's settings button never reaches an app: the compositor (`surface-manager`) catches it in
`/usr/lib/qt5/qml/KeyFilters/appLaunch.js` and opens `com.webos.app.quicksettings`, which isn't an app but QML
(`/usr/lib/qt5/qml/QuickSettings/QuickSettings.qml`) loaded inside the compositor itself. LGlow mounts its own
`QuickSettings.qml` on top (`tv/quicksettings/`, same contract: `StarfishSystemUIWindow`, `onLaunch` with
`preload` → `exit()`), just like the loading screen (`default_app_splash.png`).

The compositor keeps both in memory from power-on, so `init.d/20-compositor` (`tv/compositor.sh`) restarts it
once (`initctl restart surface-manager`) when the home, an input or live TV is on screen. Whatever input was on
screen comes back by itself. Can be turned off with `homecustom/SIN_COMPOSITOR`.

Netflix, Prime Video and YouTube ship LG's gray loading screen as their own. `tv/splash-apps.sh` mounts the one
from `tools/make-splash.py` on top (only if the original is the generic one, by md5). All three are *squashfs*
apps: SAM mounts their image (`data/images/<app>/data.img`) as an overlay on their folder the first time they
open after power-on, and that overlay would hide the mount. So the script mounts the image and the overlay first,
the same way SAM does; when the app opens, SAM finds them in `/proc/mounts` and doesn't mount them again.

## Debugging tools

- `tv/key.js` (on the TV, `/var/lib/webosbrew/tools/key.js`): simulates the remote by writing events to
  `/dev/input/event1` (LGE RCU). Example: `node /var/lib/webosbrew/tools/key.js HOME DOWN ENTER`.
  Home = 125, OK = 28, arrows 103/108/105/106. Back = 14, which arrives as `Key_Backspace` (the physical Back
  arrives as `Key_webOS_Back`).
- Screenshot:
  `luna-send -n 1 luna://com.webos.service.tv.capture/executeOneShot '{"path":"/tmp/cap.png","method":"DISPLAY","format":"PNG","width":1920,"height":1080}'`
- Home log: `/var/log/fullhome`. Compositor events: `grep NL_ /var/log/messages`.

## Regenerating the patches for another firmware

If your TV has a different version of the home, the md5s won't match. To port it:

1. Copy your TV's original QML: `ssh tv "tar cf - -C /usr/palm/applications/com.webos.app.fullhome qml" | tar xf - -C original/`
2. Copy that tree to `mod/` and apply the changes from `tv/patches/fullhome` by hand (almost all will apply with
   `patch -p1 --fuzz=3`; the rest are adjusted by looking at the context).
3. Copy the three new QML files from `tv/qml/fullhome` to `mod/qml/UserInterfaceLayer/Containers/Main/`.
4. `python3 tools/regenerar-parches.py original mod tv/patches/fullhome` generates the `.patch` files and the md5s.

Do the same with `com.webos.app.home` → `tv/patches/home`. Send a PR with your model and firmware.
