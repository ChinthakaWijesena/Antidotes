#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <shellapi.h>

#include <memory>

#include "win32_window.h"

// Custom window message & IDs for System Tray Integration
constexpr UINT kWM_TrayNotification = WM_APP + 101;
constexpr UINT kID_TrayOpen = 2001;
constexpr UINT kID_TrayExit = 2002;

// A window that hosts a Flutter view and manages Windows System Tray integration.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project, bool start_minimized = false);
  virtual ~FlutterWindow();

  void CreateTrayIcon();
  void RemoveTrayIcon();
  void ShowTrayNotification(const wchar_t* title, const wchar_t* message);

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void ShowTrayContextMenu();

  // The project to run.
  flutter::DartProject project_;

  // Start minimized flag.
  bool start_minimized_ = false;

  // Track tray icon state.
  NOTIFYICONDATAW nid_ = {};
  bool tray_icon_created_ = false;
  bool balloon_shown_ = false;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
