enum BrowserType {
  chrome,
  edge,
  firefox,
  opera,
  operaGx,
  brave,
  internetExplorer,
}

extension BrowserTypeExtension on BrowserType {
  String get displayName {
    switch (this) {
      case BrowserType.chrome:
        return 'Google Chrome';
      case BrowserType.edge:
        return 'Microsoft Edge';
      case BrowserType.firefox:
        return 'Mozilla Firefox';
      case BrowserType.opera:
        return 'Opera';
      case BrowserType.operaGx:
        return 'Opera GX';
      case BrowserType.brave:
        return 'Brave Browser';
      case BrowserType.internetExplorer:
        return 'Internet Explorer';
    }
  }

  String get processName {
    switch (this) {
      case BrowserType.chrome:
        return 'chrome.exe';
      case BrowserType.edge:
        return 'msedge.exe';
      case BrowserType.firefox:
        return 'firefox.exe';
      case BrowserType.opera:
        return 'opera.exe';
      case BrowserType.operaGx:
        return 'opera.exe';
      case BrowserType.brave:
        return 'brave.exe';
      case BrowserType.internetExplorer:
        return 'iexplore.exe';
    }
  }
}
