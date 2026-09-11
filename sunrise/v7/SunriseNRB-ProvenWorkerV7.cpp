#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <strsafe.h>

static bool game_root(wchar_t *out, DWORD cap)
{
    DWORD n = GetModuleFileNameW(nullptr, out, cap);
    if (n == 0 || n >= cap) return false;

    for (DWORD i = n; i > 0; --i) {
        if (out[i - 1] == L'\\' || out[i - 1] == L'/') {
            out[i] = L'\0';
            return true;
        }
    }
    return false;
}

static void log_line(const wchar_t *root, const wchar_t *text)
{
    wchar_t path[MAX_PATH] = {};
    if (FAILED(StringCchCopyW(path, MAX_PATH, root))) return;
    if (FAILED(StringCchCatW(path, MAX_PATH, L"\\SunriseNRB-proven-worker-v7.log"))) return;

    HANDLE f = CreateFileW(path, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE,
                           nullptr, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (f == INVALID_HANDLE_VALUE) return;

    SYSTEMTIME st = {};
    GetLocalTime(&st);
    wchar_t line[1200] = {};
    StringCchPrintfW(line, 1200, L"[%02u:%02u:%02u.%03u pid=%lu tid=%lu] %s\r\n",
                     st.wHour, st.wMinute, st.wSecond, st.wMilliseconds,
                     GetCurrentProcessId(), GetCurrentThreadId(), text);

    DWORD chars = 0;
    while (line[chars] != L'\0') ++chars;
    DWORD written = 0;
    WriteFile(f, line, chars * sizeof(wchar_t), &written, nullptr);
    CloseHandle(f);
}

static DWORD WINAPI worker(LPVOID)
{
    wchar_t root[MAX_PATH] = {};
    if (!game_root(root, MAX_PATH))
        return 101;

    log_line(root, L"WORKER START inside destiny2.exe");

    while (GetModuleHandleW(L"steam_api64.dll") == nullptr)
        Sleep(1);

    log_line(root, L"steam_api64.dll observed; ZERO post-module settling delay");

    SetEnvironmentVariableW(L"RESHADE_DISABLE_LOADING_CHECK", L"1");
    SetEnvironmentVariableW(L"SUNRISE_NRB_PROBE_COMPAT", L"1");
    SetEnvironmentVariableW(L"RESHADE_DISABLE_INPUT_HOOK", nullptr);
    log_line(root, L"MODE input hooks enabled");

    wchar_t reshade[MAX_PATH] = {};
    if (FAILED(StringCchCopyW(reshade, MAX_PATH, root)) ||
        FAILED(StringCchCatW(reshade, MAX_PATH, L"\\ReShade64.dll"))) {
        log_line(root, L"FAIL could not construct ReShade64.dll path");
        return 102;
    }

    SetLastError(ERROR_SUCCESS);
    HMODULE module = LoadLibraryW(reshade);
    DWORD err = GetLastError();

    wchar_t msg[400] = {};
    StringCchPrintfW(msg, 400, L"LoadLibraryW(ReShade64.dll) result=%p lastError=%lu", module, err);
    log_line(root, msg);

    if (module)
        log_line(root, L"PASS patched ReShade loaded from proven-style in-process worker");
    else
        log_line(root, L"FAIL patched ReShade LoadLibrary returned null");

    return module ? 0 : 103;
}

// DetourCreateProcessWithDllEx imports ordinal #1 from the injected DLL.
extern "C" __declspec(dllexport) void CALLBACK DetourFinishHelperProcess(HWND, HINSTANCE, LPSTR, int)
{
}

BOOL APIENTRY DllMain(HMODULE module, DWORD reason, LPVOID)
{
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(module);
        HANDLE h = CreateThread(nullptr, 0, worker, nullptr, 0, nullptr);
        if (h) CloseHandle(h);
    }
    return TRUE;
}
