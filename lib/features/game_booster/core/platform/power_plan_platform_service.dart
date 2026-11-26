/// Abstract contract for querying and switching Windows Power Schemes.
abstract class PowerPlanPlatformService {
  /// Standard Windows High Performance Power Scheme GUID
  static const String highPerformanceGuid = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c';

  /// Standard Windows Balanced Power Scheme GUID
  static const String balancedGuid = '381b4222-f694-41f0-9685-ff5bb260df2e';

  /// Standard Windows Ultimate Performance Power Scheme GUID
  static const String ultimatePerformanceGuid = 'e9a42b02-d5df-448d-aa00-03f14749eb61';

  /// Retrieves the GUID of the currently active Windows Power Scheme.
  Future<String?> getActivePowerPlanGuid();

  /// Sets the active Windows Power Scheme by GUID.
  Future<bool> setActivePowerPlanGuid(String guid);
}
