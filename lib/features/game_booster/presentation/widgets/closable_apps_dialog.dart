import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_icon_widget.dart';
import '../controllers/game_booster_controller.dart';

/// Modal dialog allowing the user to select which running background apps to close during gaming.
/// Safety Rule: Protected system and security processes are completely excluded from this list.
class ClosableAppsDialog extends StatefulWidget {
  final GameBoosterController controller;

  const ClosableAppsDialog({
    super.key,
    required this.controller,
  });

  @override
  State<ClosableAppsDialog> createState() => _ClosableAppsDialogState();
}

class _ClosableAppsDialogState extends State<ClosableAppsDialog> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final allApps = ctrl.runningProcesses;
    final filtered = _search.trim().isEmpty
        ? allApps
        : allApps.where((p) => p.name.toLowerCase().contains(_search.toLowerCase().trim())).toList();

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.surfaceBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.apps_rounded, color: AppColors.accent, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Select Background Apps to Close',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Only selected non-protected user apps will be closed when Game Boost starts. Protected Windows and security processes are safeguarded.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              // Search & Selection Actions
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      onChanged: (val) => setState(() => _search = val),
                      decoration: InputDecoration(
                        hintText: 'Search running processes...',
                        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.surfaceBorder)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: ctrl.selectAllClosableApps,
                    child: const Text('Select All', style: TextStyle(color: AppColors.accent, fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: ctrl.clearSelectedAppsToClose,
                    child: Text('Clear', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No matching user processes found.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (context, _) => Divider(color: AppColors.surfaceBorder, height: 1),
                        itemBuilder: (context, index) {
                          final proc = filtered[index];
                          final isSelected = ctrl.selectedAppsToClose.contains(proc.name.toLowerCase());

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (_) => ctrl.toggleAppToClose(proc.name),
                            activeColor: AppColors.accent,
                            checkColor: Colors.white,
                            secondary: AppIconWidget(
                              name: proc.name,
                              iconCachePath: proc.iconCachePath,
                              fallbackIcon: Icons.memory_rounded,
                              size: 28,
                            ),
                            title: Text(
                              proc.name,
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'PID: ${proc.pid} • Memory: ${proc.memoryMb} MB',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${ctrl.selectedAppsToClose.length} apps selected',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
