# V7 Pass-1 validation authority

Date: 2026-09-11

The tested local V7 build is the authority for the Pass-1 coexistence architecture.

## Human acceptance

**3 = BOTH**

- Project Sunrise Insert UI works.
- ReShade/DLSS works.

## Machine evidence

```text
DetourCreateProcessWithDllExW ok=1 error=87 pid=4312 tid=59904
ResumeThread result=1 error=183
MODULE SunriseNRB.dll observed
MODULE steam_api64.dll observed
MODULE ReShade64.dll observed
PASS module chain alive: bridge + Sunrise + patched ReShade
launcher handoff complete; processExit=0x00000103 bridge=1 steam=1 reshade=1
```

Worker:

```text
WORKER START inside destiny2.exe
steam_api64.dll observed; ZERO post-module settling delay
MODE input hooks enabled
```

## Tested hashes

| Component | SHA-256 |
|---|---|
| Protected Sunrise `steam_api64.dll` | `EEF191955C803D7A4B0BDC079ABEC519CD2BFD0C3909C7C19B6B7BAA078553DB` |
| Patched ReShade64.dll | `9E85F8644830338F48EF6F4DB4E0BAE66F0B3FAF9BE2189CEF26F3B65B4A8E18` |
| V7 worker bridge | `0977BCD616771A71D9E3CB78C510C1D3A03AF5265A4E465AB61B64CFDA88920F` |
| V7 launcher | `43EC5E9EF325B4EDEE7B7F44176C9DB6CD73A05F6E2B01A38D6D9B2B63CB5714` |
| DLSS5 feed | `CCC162E899B132BCDA3F80C5AE3309F0EE0FAB6254B98D0C5DA2F986AF52EE93` |

## Pinned upstream sources

- ReShade v6.8.0: `18deaa52de0c425a78b329e9cb3c497281cd00ec`
- Microsoft Detours v4.0.1: `e4bfd6b03e50de46b47abfbd1e46b384f0c5f833`

The portable release source derives paths from the launcher/game location. The injection, worker, zero-post-module-delay, ordinal-1 export, and ReShade probe-ownership logic are otherwise the locked V7 architecture.
