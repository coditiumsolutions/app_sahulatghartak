# Fix: "Lost connection to device" / DDS connection refused on `flutter run` (Windows)

**Date:** 2026-08-03 (updated same day with the actual root cause: corrupted emulator data)

## TL;DR — try this first

The actual root cause, confirmed 2026-08-03: **corrupted emulator (AVD) data**, not a Windows networking issue. Everything below about winnat/Hyper-V port exclusions was a real, reproducible symptom, but treating it as the cause led down a long rabbit hole — it turned out to just be collateral noise from the same underlying corrupted emulator state.

**Try steps 1-3 first, in order, before anything else in this doc:**

1. Wipe the emulator's data (Android Studio → Device Manager → ⋮ menu on the AVD → **Wipe Data**), or `emulator -avd <name> -wipe-data` from the command line.
2. Cold boot the emulator (Device Manager → ⋮ → **Cold Boot Now**, not a regular launch).
3. `flutter clean` in the project directory, then `flutter run -d emulator-5554`.

This resolved the issue completely — no port pinning, no winnat/Hyper-V changes needed.

**If that doesn't work**, next try deleting the AVD entirely and creating a fresh one from scratch (Device Manager → delete → create new, same device/API level). Only if *that* also fails should the port-pinning and winnat/Hyper-V mitigations further down this doc be attempted — they address a real but apparently secondary symptom, not the root cause.

## Fallback: permanent port-pinning fix (if wipe/recreate doesn't help)

`net stop winnat && net start winnat` (documented below) only clears the symptom temporarily — Windows' dynamic port exclusion list regrows within roughly an hour as `winnat`/Hyper-V's background services (`hns`, `HvHost`, `vmms`, the always-on "Default Switch" vEthernet adapter) reserve more ephemeral ports. It came back within an hour of the workaround.

An alternative mitigation is to stop relying on Dart's ephemeral port picker at all: pin the VM Service and DDS to fixed ports, and permanently reserve those ports from Windows so nothing (winnat, Hyper-V, another app) can ever claim them.

```powershell
# one-time, elevated, persists across reboots
netsh int ipv4 add excludedportrange protocol=tcp startport=43000 numberofports=10 store=persistent
```

Then always launch with:

```
flutter run -d emulator-5554 --dds-port=43000 --host-vmservice-port=43001
```

This is wired into [.vscode/launch.json](../.vscode/launch.json) as the "Flutter (fixed VM Service ports)" configuration, so VS Code's Run/Debug uses it automatically. For manual CLI runs, use the flags above.

## Symptom

`flutter run -d emulator-5554` builds and installs the APK fine, but then fails with either:

```
Lost connection to device.
```

or

```
Error connecting to the service protocol: failed to connect to http://127.0.0.1:PORT/.../
DartDevelopmentServiceException: WebSocketChannelException:
SocketException: The remote computer refused the network connection
(OS Error: The remote computer refused the network connection, errno = 1225), address = 127.0.0.1, port = PORT2
```

Emulator itself stays running and healthy the whole time (`adb devices` shows `device`, no emulator crash logs).

## Root cause

Windows/`winnat` (the NAT service backing Hyper-V and WSL2 networking) accumulates **dynamic TCP port exclusion ranges** over time (visible via `netsh interface ipv4 show excludedportrange protocol=tcp`). These ranges only grow, never shrink, across service/Docker/WSL restarts.

Dart's ephemeral port picker (used by the VM Service and DDS to bind local loopback sockets) has no awareness of these OS-level exclusions. When it happens to pick a port that falls inside an excluded range, Windows immediately refuses any connection to it — producing the exact "remote computer refused the network connection" error, on `127.0.0.1`, for no apparent reason.

## What fixed it (temporary — superseded by the permanent fix above)

Restart the `winnat` service (as Administrator):

```powershell
net stop winnat
net start winnat
```

This forces Windows to recompute the exclusion ranges. In this case it dropped from ~19 reserved ranges down to 6, freeing the 62000–63999 range that Dart kept colliding with.

**Note:** Stop WSL first if it's running (`wsl --shutdown`), since winnat restart briefly disrupts Hyper-V/WSL/Docker NAT. Not required if WSL is already off.

## What did NOT fix it (ruled out, in order tried)

1. **Stale `skin.path` in AVD `config.ini`** — this was a real, separate bug from the earlier C:→D: SDK migration (fixed by pointing `skin.path` at the new SDK location), but it only caused the emulator to fail to *launch*. It was not the cause of this connection issue, which occurs after the emulator is already running fine.
2. **`flutter upgrade --force` (3.44.8) suspected as regression** — downgraded the Flutter SDK via `git checkout` to the prior commit (3.44.7, pre-upgrade). Same failure occurred on both versions, ruling out the Flutter upgrade as the cause.
3. **`--no-dds` flag** — bypasses the separate Dart Development Service process. Sometimes let the app run briefly, but was not a reliable fix since the underlying VM Service connection could still get an excluded port.
4. **Windows Defender real-time scanning** — added exclusions for `D:\ryDevelop` and the project folder, plus process exclusions for `emulator.exe`, `adb.exe`, etc. No effect.
5. **OpenVPN Connect background services** (`agent_ovpnconnect`, `ovpnhelper_service`) — suspected of installing WFP filters that intercept loopback traffic. Stopped both services; no effect. (Restarted afterward since they weren't the cause.)
6. **ADB server restart** (`adb kill-server` / `adb start-server`) — fixed an unrelated transient "device offline" state but did not fix the port-refused issue.

## Root cause, deeper: two independent port-reservation layers

Windows has (at least) two systems that dynamically reserve TCP ports out of the ephemeral range (49152–65535 by default), neither of which Dart's port picker is aware of:

1. **`winnat`** (NAT service backing Hyper-V/WSL2/Docker) — accumulates dynamic exclusion ranges over time, visible via `netsh interface ipv4 show excludedportrange protocol=tcp`. Only grows, never shrinks, until the service is restarted.
2. **Hyper-V's host networking stack** (`hns`, `HvHost`, `vmms` services, plus an always-on "Default Switch" `vEthernet` adapter) — active in the background even with no VM or WSL distro currently running, as long as Hyper-V/WSL2/Docker Desktop are installed. This is a separate reservation mechanism from winnat's exclusion list and was still causing `errno 1225` refusals on ports that were *not* in winnat's excluded-range list.

Because both layers can claim a port Dart just bound, restarting winnat only ever fixes the first layer, and only until it regrows. Pinning + permanently excluding fixed ports (see TL;DR) sidesteps both.

## Diagnostic tip

If similar symptoms recur (`errno 1225`, refused loopback connection) even with fixed ports in use, first confirm the fixed range is still reserved:

```powershell
netsh interface ipv4 show excludedportrange protocol=tcp
```

Port range 43000–43009 should always appear there (marked with `*`, persistent). If it's missing, re-run the `netsh ... add excludedportrange ... store=persistent` command from the TL;DR as Administrator.

## Known remaining issue (superseded)

Even with fixed ports, a run could still end in a silent `Lost connection to device` a few seconds after the app renders, with no exception logged. This turned out to be another symptom of the same corrupted emulator data — resolved by the wipe-data + cold-boot + `flutter clean` fix at the top of this doc, not by any networking change.

## Resolution (2026-08-03)

Confirmed fix, in this order:

1. Flutter channel set to `stable` and up to date (3.44.8) — unrelated cleanup, done first, did not by itself fix the issue.
2. Wiped the emulator's data.
3. Cold-booted the emulator.
4. `flutter clean` in the project directory.
5. `flutter run -d emulator-5554` — worked, stayed connected.

No port pinning or Windows networking changes were needed once the emulator data was wiped. The winnat/Hyper-V port exclusion behavior documented above is real and can independently cause `errno 1225`, but was not the actual cause of the persistent connection failures in this case — corrupted AVD state was. Treat this fix as the first thing to try; treat the networking mitigations as a fallback only if wiping/recreating the AVD doesn't help.
