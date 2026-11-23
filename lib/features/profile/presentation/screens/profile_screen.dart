import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  final AuthController authController;
  final ProfileController profileController;

  const ProfileScreen({
    super.key,
    required this.authController,
    required this.profileController,
  });

  static void show(
    BuildContext context, {
    required AuthController authController,
    required ProfileController profileController,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, minWidth: 320),
          child: ProfileScreen(
            authController: authController,
            profileController: profileController,
          ),
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final currentName = profileController.profile?.displayName ??
        authController.currentUser?.displayName ??
        '';
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        title: Text(
          'Edit Display Name',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter new name',
            hintStyle: TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.surfaceBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await authController.updateDisplayName(newName);
                await profileController.updateDisplayName(newName);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGlow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_circle_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'User Profile & Cloud Sync',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: AppColors.textMuted, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // User Info Card
          ListenableBuilder(
            listenable: profileController,
            builder: (context, _) {
              final profile = profileController.profile;
              final user = authController.currentUser;
              final displayName =
                  profile?.displayName ?? user?.displayName ?? 'Guest User';
              final email = profile?.email ?? user?.email ?? 'Not signed in';
              final tier = profile?.tier ??
                  (authController.isGuestMode ? 'Guest Mode' : 'Free Standard');
              final initials = user?.initials ?? 'G';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder, width: 1),
                ),
                child: Row(
                  children: [
                    // Avatar Circle
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (authController.isAuthenticated) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => _showEditNameDialog(context),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    color: AppColors.textMuted,
                                    size: 15,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGlow,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              tier,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          // Statistics Grid (Cloud Firestore Synced)
          Text(
            'Optimization Activity (Cloud Synced)',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          ListenableBuilder(
            listenable: profileController,
            builder: (context, _) {
              final profile = profileController.profile;
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.cleaning_services_rounded,
                      title: 'Junk Cleaned',
                      value: profile?.formattedCleanedStorage ?? '0 MB',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.memory_rounded,
                      title: 'RAM Freed',
                      value: '${profile?.totalRamOptimizations ?? 0} times',
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.dns_rounded,
                      title: 'DNS Switches',
                      value: '${profile?.totalDnsSwitches ?? 0}',
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // Cloud Sync Info Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                Icon(
                  authController.isAuthenticated
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  color: authController.isAuthenticated
                      ? AppColors.success
                      : AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authController.isAuthenticated
                            ? 'Cloud Database Connected'
                            : 'Guest Mode - Local Only',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        authController.isAuthenticated
                            ? 'Your preferences and stats are synced to Firestore.'
                            : 'Sign in to sync your stats and settings across devices.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (authController.isAuthenticated)
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await authController.logout();
                  },
                  icon: const Icon(Icons.logout_rounded,
                      color: AppColors.danger, size: 16),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger, width: 1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    authController.logout(); // Triggers login screen
                  },
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text('Sign In / Register'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
