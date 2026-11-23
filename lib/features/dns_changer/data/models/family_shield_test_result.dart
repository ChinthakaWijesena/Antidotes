class FamilyShieldTestResult {
  final bool isAdultBlocked;
  final bool isSafeSearchEnforced;
  final bool isIpv6Protected;
  final String details;

  const FamilyShieldTestResult({
    required this.isAdultBlocked,
    required this.isSafeSearchEnforced,
    required this.isIpv6Protected,
    required this.details,
  });

  bool get isFullyProtected => isAdultBlocked && isSafeSearchEnforced && isIpv6Protected;
}
