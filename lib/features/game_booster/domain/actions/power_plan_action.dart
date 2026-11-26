import '../../core/platform/power_plan_platform_service.dart';
import 'boost_action.dart';

/// Switches the active Windows Power Scheme to High Performance when boosted,
/// and reverts back to the original power scheme when the session ends.
class PowerPlanAction implements BoostAction {
  static const String stateKey = 'original_power_plan_guid';

  @override
  String get name => 'High Performance Power Plan';

  @override
  Future<void> apply(BoostContext context) async {
    // 1. Save original power plan GUID before switching
    final currentGuid = await context.powerPlanService.getActivePowerPlanGuid();
    if (currentGuid != null) {
      context.sessionState[stateKey] = currentGuid;
    }

    // 2. Switch to High Performance plan
    await context.powerPlanService.setActivePowerPlanGuid(
      PowerPlanPlatformService.highPerformanceGuid,
    );
  }

  @override
  Future<void> revert(BoostContext context) async {
    final originalGuid = context.sessionState[stateKey] as String?;
    if (originalGuid != null && originalGuid.isNotEmpty) {
      await context.powerPlanService.setActivePowerPlanGuid(originalGuid);
    }
  }
}
