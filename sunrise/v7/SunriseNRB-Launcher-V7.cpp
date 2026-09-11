#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <tlhelp32.h>
#include <strsafe.h>
#include <detours.h>
#include <stdio.h>

static bool dirname_in_place(wchar_t *path)
{
    size_t len = wcslen(path);
    for (size_t i = len; i > 0; --i) {
        if (path[i - 1] == L'\\' || path[i - 1] == L'/') {
            path[i - 1] = L'\0';
            return true;
        }
    }
    return false;
}

static bool self_paths(
    wchar_t *root, size_t rootCap,
    wchar_t *game, size_t gameCap,
    wchar_t *bridgeW, size_t bridgeWCap,
    char *bridgeA, size_t bridgeACap,
    wchar_t *log, size_t logCap)
{
    wchar_t bridgeDir[MAX_PATH] = {};
    DWORD n = GetModuleFileNameW(nullptr, bridgeDir, MAX_PATH);
    if (n == 0 || n >= MAX_PATH) return false;
    if (!dirname_in_place(bridgeDir)) return false;

    if (FAILED(StringCchCopyW(root, rootCap, bridgeDir))) return false;
    if (!dirname_in_place(root)) return false;

    if (FAILED(StringCchCopyW(game, gameCap, root))) return false;
    if (FAILED(StringCchCatW(game, gameCap, L"\\destiny2.exe"))) return false;

    if (FAILED(StringCchCopyW(bridgeW, bridgeWCap, bridgeDir))) return false;
    if (FAILED(StringCchCatW(bridgeW, bridgeWCap, L"\\SunriseNRB.dll"))) return false;

    if (WideCharToMultiByte(CP_ACP, 0, bridgeW, -1, bridgeA, static_cast<int>(bridgeACap),
                            nullptr, nullptr) == 0)
        return false;

    if (FAILED(StringCchCopyW(log, logCap, root))) return false;
    if (FAILED(StringCchCatW(log, logCap, L"\\SunriseNRB-launcher-v7.log"))) return false;

    return true;
}

static void log_line(const wchar_t *log, const wchar_t *text)
{
    HANDLE f = CreateFileW(log, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE,
                           nullptr, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (f != INVALID_HANDLE_VALUE) {
        SYSTEMTIME st = {};
        GetLocalTime(&st);
        wchar_t line[1200] = {};
        StringCchPrintfW(line, 1200, L"[%02u:%02u:%02u.%03u] %s\r\n",
                         st.wHour, st.wMinute, st.wSecond, st.wMilliseconds, text);
        DWORD chars = 0;
        while (line[chars] != L'\0') ++chars;
        DWORD written = 0;
        WriteFile(f, line, chars * sizeof(wchar_t), &written, nullptr);
        CloseHandle(f);
    }

    wprintf(L"%s\n", text);
    fflush(stdout);
}

static bool has_module(DWORD pid, const wchar_t *wanted)
{
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32, pid);
    if (snap == INVALID_HANDLE_VALUE) return false;

    MODULEENTRY32W me = {};
    me.dwSize = sizeof(me);
    bool found = false;

    if (Module32FirstW(snap, &me)) {
        do {
            if (_wcsicmp(me.szModule, wanted) == 0) {
                found = true;
                break;
            }
        } while (Module32NextW(snap, &me));
    }

    CloseHandle(snap);
    return found;
}

int wmain()
{
    wchar_t root[MAX_PATH] = {};
    wchar_t game[MAX_PATH] = {};
    wchar_t bridgeW[MAX_PATH] = {};
    char bridgeA[MAX_PATH * 3] = {};
    wchar_t log[MAX_PATH] = {};

    if (!self_paths(root, MAX_PATH, game, MAX_PATH, bridgeW, MAX_PATH,
                    bridgeA, sizeof(bridgeA), log, MAX_PATH)) {
        fwprintf(stderr, L"Could not derive Project Sunrise paths from launcher location.\n");
        return 9;
    }

    DeleteFileW(log);
    log_line(log, L"V7 launcher start");

    wchar_t msg[1024] = {};
    StringCchPrintfW(msg, 1024, L"game=%s", game);
    log_line(log, msg);
    StringCchPrintfW(msg, 1024, L"bridge=%s", bridgeW);
    log_line(log, msg);

    if (GetFileAttributesW(game) == INVALID_FILE_ATTRIBUTES) {
        StringCchPrintfW(msg, 1024, L"FAIL destiny2.exe missing; error=%lu", GetLastError());
        log_line(log, msg);
        return 10;
    }

    if (GetFileAttributesW(bridgeW) == INVALID_FILE_ATTRIBUTES) {
        StringCchPrintfW(msg, 1024, L"FAIL SunriseNRB.dll missing; error=%lu", GetLastError());
        log_line(log, msg);
        return 11;
    }

    STARTUPINFOW si = {};
    si.cb = sizeof(si);
    PROCESS_INFORMATION pi = {};

    wchar_t cmd[MAX_PATH * 2] = {};
    StringCchPrintfW(cmd, ARRAYSIZE(cmd), L"\"%s\"", game);

    SetLastError(ERROR_SUCCESS);
    BOOL ok = DetourCreateProcessWithDllExW(
        game, cmd,
        nullptr, nullptr, FALSE,
        CREATE_DEFAULT_ERROR_MODE | CREATE_SUSPENDED,
        nullptr, root,
        &si, &pi,
        bridgeA,
        nullptr);

    DWORD createErr = GetLastError();
    StringCchPrintfW(msg, 1024,
        L"DetourCreateProcessWithDllExW ok=%d error=%lu pid=%lu tid=%lu",
        ok ? 1 : 0, createErr, pi.dwProcessId, pi.dwThreadId);
    log_line(log, msg);

    if (!ok) return 20;

    DWORD resume = ResumeThread(pi.hThread);
    DWORD resumeErr = GetLastError();
    StringCchPrintfW(msg, 1024, L"ResumeThread result=%lu error=%lu", resume, resumeErr);
    log_line(log, msg);

    if (resume == (DWORD)-1) {
        TerminateProcess(pi.hProcess, 0xE001);
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
        return 21;
    }

    log_line(log, L"process resumed; observing runtime for 30 seconds");

    bool sawBridge = false, sawSteam = false, sawReShade = false;
    for (int i = 0; i < 300; ++i) {
        DWORD code = STILL_ACTIVE;
        if (!GetExitCodeProcess(pi.hProcess, &code)) {
            StringCchPrintfW(msg, 1024, L"GetExitCodeProcess failed error=%lu", GetLastError());
            log_line(log, msg);
            break;
        }

        if (code != STILL_ACTIVE) {
            StringCchPrintfW(msg, 1024, L"PROCESS EXITED EARLY exitCode=0x%08lX (%lu)", code, code);
            log_line(log, msg);
            CloseHandle(pi.hThread);
            CloseHandle(pi.hProcess);
            return 30;
        }

        bool b = has_module(pi.dwProcessId, L"SunriseNRB.dll");
        bool s = has_module(pi.dwProcessId, L"steam_api64.dll");
        bool r = has_module(pi.dwProcessId, L"ReShade64.dll");

        if (b && !sawBridge) { log_line(log, L"MODULE SunriseNRB.dll observed"); sawBridge = true; }
        if (s && !sawSteam)  { log_line(log, L"MODULE steam_api64.dll observed"); sawSteam = true; }
        if (r && !sawReShade){ log_line(log, L"MODULE ReShade64.dll observed"); sawReShade = true; }

        if (sawBridge && sawSteam && sawReShade) {
            log_line(log, L"PASS module chain alive: bridge + Sunrise + patched ReShade");
            break;
        }

        Sleep(100);
    }

    DWORD finalCode = STILL_ACTIVE;
    GetExitCodeProcess(pi.hProcess, &finalCode);
    StringCchPrintfW(msg, 1024,
        L"launcher handoff complete; processExit=0x%08lX bridge=%d steam=%d reshade=%d",
        finalCode, sawBridge ? 1 : 0, sawSteam ? 1 : 0, sawReShade ? 1 : 0);
    log_line(log, msg);

    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);

    return (sawBridge && sawSteam && sawReShade && finalCode == STILL_ACTIVE) ? 0 : 40;
}
