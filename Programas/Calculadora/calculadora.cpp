#ifndef UNICODE
#define UNICODE
#endif

#include <windows.h>
#include <string>

// Identificadores de controles
#define ID_BTN_ADD 101
#define ID_BTN_SUB 102
#define ID_BTN_MUL 103
#define ID_BTN_DIV 104
#define ID_EDIT_A  105
#define ID_EDIT_B  106
#define ID_RESULT  107

HWND hEditA, hEditB, hStaticRes;

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch (uMsg) {
    case WM_CREATE: {
        // Interfaz minimalista optimizada
        CreateWindow(L"STATIC", L"Número A:", WS_VISIBLE | WS_CHILD, 10, 10, 80, 20, hwnd, NULL, NULL, NULL);
        hEditA = CreateWindow(L"EDIT", L"", WS_VISIBLE | WS_CHILD | WS_BORDER | ES_NUMBER, 100, 10, 100, 20, hwnd, (HMENU)ID_EDIT_A, NULL, NULL);

        CreateWindow(L"STATIC", L"Número B:", WS_VISIBLE | WS_CHILD, 10, 40, 80, 20, hwnd, NULL, NULL, NULL);
        hEditB = CreateWindow(L"EDIT", L"", WS_VISIBLE | WS_CHILD | WS_BORDER | ES_NUMBER, 100, 40, 100, 20, hwnd, (HMENU)ID_EDIT_B, NULL, NULL);

        CreateWindow(L"BUTTON", L"+", WS_VISIBLE | WS_CHILD, 10, 80, 40, 30, hwnd, (HMENU)ID_BTN_ADD, NULL, NULL);
        CreateWindow(L"BUTTON", L"-", WS_VISIBLE | WS_CHILD, 60, 80, 40, 30, hwnd, (HMENU)ID_BTN_SUB, NULL, NULL);
        CreateWindow(L"BUTTON", L"*", WS_VISIBLE | WS_CHILD, 110, 80, 40, 30, hwnd, (HMENU)ID_BTN_MUL, NULL, NULL);
        CreateWindow(L"BUTTON", L"/", WS_VISIBLE | WS_CHILD, 160, 80, 40, 30, hwnd, (HMENU)ID_BTN_DIV, NULL, NULL);

        hStaticRes = CreateWindow(L"STATIC", L"Resultado: ", WS_VISIBLE | WS_CHILD, 10, 120, 200, 20, hwnd, (HMENU)ID_RESULT, NULL, NULL);
        break;
    }

    case WM_COMMAND: {
        if (LOWORD(wParam) >= ID_BTN_ADD && LOWORD(wParam) <= ID_BTN_DIV) {
            wchar_t bufA[16], bufB[16];
            GetWindowText(hEditA, bufA, 16);
            GetWindowText(hEditB, bufB, 16);

            double a = _wtof(bufA);
            double b = _wtof(bufB);
            double res = 0;

            switch (LOWORD(wParam)) {
                case ID_BTN_ADD: res = a + b; break;
                case ID_BTN_SUB: res = a - b; break;
                case ID_BTN_MUL: res = a * b; break;
                case ID_BTN_DIV: res = (b != 0) ? a / b : 0; break;
            }

            std::wstring out = L"Resultado: " + std::to_wstring(res);
            SetWindowText(hStaticRes, out.c_str());
        }
        break;
    }

    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    const wchar_t CLASS_NAME[] = L"CalcWindowClass";
    WNDCLASS wc = {};
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = CLASS_NAME;
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);

    RegisterClass(&wc);

    HWND hwnd = CreateWindowEx(0, CLASS_NAME, L"Calculadora Ultra-Optimizada", WS_OVERLAPPEDWINDOW, 
                               CW_USEDEFAULT, CW_USEDEFAULT, 240, 200, NULL, NULL, hInstance, NULL);

    if (hwnd == NULL) return 0;

    ShowWindow(hwnd, nCmdShow);

    MSG msg = {};
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return 0;
}