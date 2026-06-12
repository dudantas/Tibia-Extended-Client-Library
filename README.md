This code is distributed "as-is" without any license in the hope that it will be useful.\
Code was writen for studying purpose and I don't take any responsibility for how it is used.

# Current Features
* Extended client files(exceeds the 65535 sprite limit)
* Alpha channel .spr file(allows to use transparency(currently only work in DX9 and OGL)
* Show health/mana percentage in client
* Fix some weird problem with timeGetTime on windows 10+ryzen cpu
* Manabar drawing below player
* Exceeds the limit of 255 magic effects
* Exceeds the limit of 65535 max health display
* Exceeds the limit of 65535 max mana display
* Exceeds the limit of 255 skills display

# Building
Create a dynamic link library project, name it and save.\
Make sure your target filename is ddraw.dll\
Link opengl32 to your project.\
Always compile as release 32bit.

## Canary 8.60 build helper

The repository includes a PowerShell build helper for the Canary-compatible 8.60 extended client DLL. Run it from the repository root:

```powershell
.\scripts\build-canary-860-msvc-x86.ps1
```

By default it writes `ddraw.dll` to `build/canary-860`. It uses the current Visual Studio Developer environment when available; otherwise it discovers `VsDevCmd.bat` with `vswhere`. If discovery is not possible, pass the path explicitly:

```powershell
.\scripts\build-canary-860-msvc-x86.ps1 -VsDevCmd "<path-to-vsdevcmd.bat>"
```

Useful options:

```powershell
.\scripts\build-canary-860-msvc-x86.ps1 -OutDir artifacts/canary-860
.\scripts\build-canary-860-msvc-x86.ps1 -InstallDir path/to/client
.\scripts\build-canary-860-msvc-x86.ps1 -Clean
```

The helper also supports named build profiles:

```powershell
.\scripts\build-canary-860-msvc-x86.ps1 -Profile canary-860
.\scripts\build-canary-860-msvc-x86.ps1 -Profile client-11 -InstallDir path/to/client-11
```

For convenience, `scripts/build-client11-msvc-x86.ps1` wraps the `client-11` profile.

The default Canary 8.60 defines are `__INCLUDE_860_VERSION__`, `__CONFIG__`, and `__MAGIC_EFFECTS_U16__`. To override them:

```powershell
.\scripts\build-canary-860-msvc-x86.ps1 -Defines __INCLUDE_860_VERSION__,__CONFIG__,__MAGIC_EFFECTS_U16__
```

The `client-11` profile targets the CipSoft-like executable with entrypoint `0x38D218` and patches the verified `600000` sprite cap so `.spr` files with 15.11-era sprite counts can load. It does not patch gameplay protocol, render hooks, item remapping, or unverified object/outfit/effect caps.

The legacy `.cmd` script is kept as a wrapper around the PowerShell script for convenience.

### Preprocesor Defines
**-D__INCLUDE_854_VERSION__**\
inludes 8.54 client version target\
**-D__INCLUDE_860_VERSION__**\
includes 8.60 client version target\
**-D__INCLUDE_CLIENT11_VERSION__**\
includes the experimental client-11 asset-limit target\
**-D__CONFIG__**\
allows to customize extended options via config.ini\
**-D__MAGIC_EFFECTS_U16__**\
changes the magic effects game protocol usage of uint8_t to uint16_t\
**-D__PLAYER_HEALTH_U32__**\
changes the player health game protocol usage of uint16_t to int32_t - 0x7FFFFFFF limit\
**-D__PLAYER_MANA_U32__**\
changes the player mana game protocol usage of uint16_t to int32_t - 0x7FFFFFFF limit\
**-D__PLAYER_SKILLS_U16__**\
changes the player skills value game protocol usage of uint8_t to uint16_t - can be used custom skills system\
**-D__EXTENDED_FILE__**\
use the extended .spr and .dat files(only if not defined **-D__CONFIG__**)\
**-D__ALPHA_SPRITES__**\
use the alpha channel in .spr file(only if not defined **-D__CONFIG__**)\
**-D__MANABAR__**\
force the manabar to be visible(only if not defined **-D__CONFIG__**)

## config.ini

When the DLL is built with `__CONFIG__`, it reads `config.ini` from the client directory. Existing options are still supported, and spacing around `=` is optional:

```ini
hirestimer = false
extended = true
alpha = false
cachesprites = false
drawmanabar = false

# Optional local login redirect. This avoids editing the client executable.
loginHost = 127.0.0.1
loginPort = 7175
redirectConnections = true
```

`loginHost` accepts `localhost` or an IPv4 address. When enabled, the DLL redirects outbound IPv4 `connect()` calls to the configured host. If `loginPort` is set, the DLL applies it only to the first successful login connection and keeps later game-world connections on the port returned by the server.

The redirect hook writes basic connection diagnostics to `extended-client.log` in the client directory.
