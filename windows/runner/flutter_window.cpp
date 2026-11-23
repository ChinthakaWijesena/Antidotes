#include "flutter_window.h"

#include <optional>
#include <shellapi.h>

#include "flutter/generated_plugin_registrant.h"
#include "resource.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project, bool start_minimized)
    : project_(project), start_minimized_(start_minimized) {}

FlutterWindow::~FlutterWindow() {
  RemoveTrayIcon();
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Create System Tray icon in the Windows Notification Area / Overflow Menu
  CreateTrayIcon();

  if (!start_minimized_) {
    flutter_controller_->engine()->SetNextFrameCallback([&]() {
      this->Show();
    });

    // Flutter can complete the first frame before the "show window" callback is
    // registered. The following call ensures a frame is pending to ensure the
    // window is shown. It is a no-op if the first frame hasn't completed yet.
    flutter_controller_->ForceRedraw();
  }

  return true;
}

void FlutterWindow::OnDestroy() {
  RemoveTrayIcon();

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

void FlutterWindow::CreateTrayIcon() {
  if (tray_icon_created_) return;
  HWND hwnd = GetHandle();
  if (!hwnd) return;

  memset(&nid_, 0, sizeof(nid_));
  nid_.cbSize = sizeof(NOTIFYICONDATAW);
  nid_.hWnd = hwnd;
  nid_.uID = 1;
  nid_.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  nid_.uCallbackMessage = kWM_TrayNotification;

  nid_.hIcon = (HICON)::LoadImage(
      ::GetModuleHandle(nullptr),
      MAKEINTRESOURCE(IDI_APP_ICON),
      IMAGE_ICON,
      ::GetSystemMetrics(SM_CXSMICON),
      ::GetSystemMetrics(SM_CYSMICON),
      LR_DEFAULTCOLOR);
  if (!nid_.hIcon) {
    nid_.hIcon = ::LoadIcon(nullptr, IDI_APPLICATION);
  }

  wcscpy_s(nid_.szTip, L"Antidotes - PC Optimizer");

  if (::Shell_NotifyIconW(NIM_ADD, &nid_)) {
    tray_icon_created_ = true;
  }
}

void FlutterWindow::RemoveTrayIcon() {
  if (tray_icon_created_) {
    ::Shell_NotifyIconW(NIM_DELETE, &nid_);
    tray_icon_created_ = false;
  }
}

void FlutterWindow::ShowTrayContextMenu() {
  HWND hwnd = GetHandle();
  if (!hwnd) return;

  POINT pt;
  ::GetCursorPos(&pt);

  HMENU hMenu = ::CreatePopupMenu();
  ::AppendMenuW(hMenu, MF_STRING, kID_TrayOpen, L"Open Antidotes");
  ::AppendMenuW(hMenu, MF_SEPARATOR, 0, nullptr);
  ::AppendMenuW(hMenu, MF_STRING, kID_TrayExit, L"Exit");

  ::SetForegroundWindow(hwnd);
  ::TrackPopupMenu(hMenu, TPM_RIGHTBUTTON | TPM_BOTTOMALIGN, pt.x, pt.y, 0, hwnd, nullptr);
  ::DestroyMenu(hMenu);
}

void FlutterWindow::ShowTrayNotification(const wchar_t* title, const wchar_t* message) {
  if (!tray_icon_created_) return;
  nid_.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP | NIF_INFO;
  wcscpy_s(nid_.szInfoTitle, title);
  wcscpy_s(nid_.szInfo, message);
  nid_.dwInfoFlags = NIIF_INFO;
  ::Shell_NotifyIconW(NIM_MODIFY, &nid_);
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;

    case kWM_TrayNotification: {
      switch (LOWORD(lparam)) {
        case WM_LBUTTONUP:
        case WM_LBUTTONDBLCLK:
          ::ShowWindow(hwnd, SW_SHOW);
          ::ShowWindow(hwnd, SW_RESTORE);
          ::SetForegroundWindow(hwnd);
          break;
        case WM_RBUTTONUP:
        case WM_CONTEXTMENU:
          ShowTrayContextMenu();
          break;
      }
      return 0;
    }

    case WM_COMMAND: {
      switch (LOWORD(wparam)) {
        case kID_TrayOpen:
          ::ShowWindow(hwnd, SW_SHOW);
          ::ShowWindow(hwnd, SW_RESTORE);
          ::SetForegroundWindow(hwnd);
          return 0;
        case kID_TrayExit:
          RemoveTrayIcon();
          ::DestroyWindow(hwnd);
          return 0;
      }
      break;
    }

    case WM_CLOSE: {
      // Minimize to system tray overflow area instead of killing the process
      ::ShowWindow(hwnd, SW_HIDE);
      if (!balloon_shown_) {
        ShowTrayNotification(
            L"Antidotes - PC Optimizer",
            L"Antidotes is running in the background. Click the tray icon to reopen.");
        balloon_shown_ = true;
      }
      return 0;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
