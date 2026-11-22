import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/system_restore_service.dart';
import '../../../../core/theme/app_theme_scope.dart';
import '../../data/models/startup_app_item.dart';
import '../controllers/startup_manager_controller.dart';

class StartupManagerScreen extends StatefulWidget {
  const StartupManagerScreen({super.key});

  @override
  State<StartupManagerScreen> createState() => _StartupManagerScreenState();
}

class _StartupManagerScreenState extends State<StartupManagerScreen> {
  late final StartupManagerController _controller;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = StartupManagerController();
    _controller.addListener(_onUpdate);
    _controller.loadApps();
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    setState(() {});
  }

  void _showPropertiesDialog(StartupAppItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.surfaceBorder),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _propRow('Publisher', item.publisher),
              const SizedBox(height: 10),
              _propRow('Startup Location', item.location),
              const SizedBox(height: 10),
              _propRow('Status', item.isEnabled ? 'Enabled' : 'Disabled'),
              const SizedBox(height: 10),
              _propRow('Startup Impact', item.impactLabel),
              const SizedBox(height: 10),
              if (item.packageFamilyName.isNotEmpty) ...[
                _propRow('Package Family', item.packageFamilyName),
                const SizedBox(height: 10),
                _propRow('Task ID', item.taskId),
                const SizedBox(height: 10),
              ],
              Text(
                'Command Line / Target:',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: SelectableText(
                  item.command,
                  style: TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _promptCreateRestorePoint() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.surfaceBorder),
        ),
        title: Row(
          children: [
            Icon(Icons.settings_backup_restore_rounded,
                color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            Text(
              'Create System Restore Point',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Text(
            'Creating a Windows Restore Point creates a system snapshot before you enable or disable startup programs.\n\nWould you like to create one now?',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create Point'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.surfaceBorder),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Creating System Restore Point...\nPlease approve UAC if prompted.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final srService = SystemRestoreService();
      final res = await srService.createRestorePoint(
        'Antidotes - Startup Apps (${DateTime.now().toString().split('.')[0]})',
      );

      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor:
                res.isSuccess ? AppColors.success : AppColors.warning,
          ),
        );
      }
    }
  }

  Widget _propRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.of(context);
    final apps = _controller.filteredApps;
    final selected = _controller.selectedItem;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar (Task Manager Style)
              _buildTopBar(selected),
              const SizedBox(height: 14),

              // Action Bar (Enable, Disable, Properties, BIOS Time)
              _buildActionBar(selected),
              const SizedBox(height: 14),

              // Apps Data Table
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    children: [
                      // Table Column Headers
                      _buildTableHeader(),
                      const Divider(height: 1),

                      // Table Body Rows
                      Expanded(
                        child: _controller.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : apps.isEmpty
                                ? Center(
                                    child: Text(
                                      'No matching startup apps found',
                                      style: TextStyle(
                                          color: AppColors.textSecondary),
                                    ),
                                  )
                                : ListView.builder(
                                    key: const PageStorageKey('startup_apps_list'),
                                    itemCount: apps.length,
                                    itemBuilder: (context, index) {
                                      final item = apps[index];
                                      final isSelected = selected?.id == item.id;
                                      return _buildTableRow(item, isSelected);
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
              // Bottom Status Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_controller.totalApps} startup apps (${_controller.enabledApps} enabled, ${_controller.disabledApps} disabled)',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Task Manager Compatible Engine',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(StartupAppItem? selected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Startup apps',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),

        // Search Box (like Windows 11 Task Manager)
        SizedBox(
          width: 380,
          height: 38,
          child: TextField(
            controller: _searchController,
            onChanged: (val) => _controller.setSearchQuery(val),
            decoration: InputDecoration(
              hintText: 'Type a name, publisher, or command to search',
              hintStyle:
                  TextStyle(color: AppColors.textMuted, fontSize: 12),
              prefixIcon: Icon(Icons.search_rounded,
                  size: 18, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.surfaceBorder),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar(StartupAppItem? selected) {
    final canEnable = selected != null && !selected.isEnabled;
    final canDisable = selected != null && selected.isEnabled;

    return Row(
      children: [
        // Enable Button
        OutlinedButton.icon(
          onPressed: canEnable
              ? () async {
                  await _controller.toggleSelectedItem(true);
                }
              : null,
          icon: const Icon(Icons.check_rounded, size: 16),
          label: const Text('Enable'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            foregroundColor: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),

        // Disable Button
        OutlinedButton.icon(
          onPressed: canDisable
              ? () async {
                  await _controller.toggleSelectedItem(false);
                }
              : null,
          icon: const Icon(Icons.block_rounded, size: 16),
          label: const Text('Disable'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            foregroundColor: AppColors.danger,
          ),
        ),
        const SizedBox(width: 8),

        // Properties Button
        OutlinedButton.icon(
          onPressed:
              selected != null ? () => _showPropertiesDialog(selected) : null,
          icon: const Icon(Icons.list_alt_rounded, size: 16),
          label: const Text('Properties'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        const SizedBox(width: 8),

        // Create System Restore Point Button
        Tooltip(
          message:
              'Create a Windows System Restore Point before modifying apps',
          child: OutlinedButton.icon(
            onPressed: _promptCreateRestorePoint,
            icon: const Icon(Icons.settings_backup_restore_rounded, size: 16),
            label: const Text('Restore Point'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Refresh Button
        IconButton(
          tooltip: 'Refresh apps list',
          onPressed: _controller.isLoading ? null : () => _controller.loadApps(),
          icon: const Icon(Icons.refresh_rounded, size: 18),
        ),

        const Spacer(),

        // BIOS Time indicator (exact replica of Task Manager)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.speed_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Last BIOS time: ${_controller.biosTime}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: _headerCell('Name', StartupSortField.name),
          ),
          Expanded(
            flex: 3,
            child: _headerCell('Publisher', StartupSortField.publisher),
          ),
          Expanded(
            flex: 2,
            child: _headerCell('Status', StartupSortField.status),
          ),
          Expanded(
            flex: 2,
            child: _headerCell('Startup impact', StartupSortField.impact),
          ),
          const SizedBox(width: 60), // Toggle switch column
        ],
      ),
    );
  }

  Widget _headerCell(String title, StartupSortField field) {
    final isCurrent = _controller.sortField == field;

    return InkWell(
      onTap: () => _controller.sortBy(field),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isCurrent) ...[
            const SizedBox(width: 4),
            Icon(
              _controller.sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableRow(StartupAppItem item, bool isSelected) {
    return InkWell(
      key: ValueKey(item.id),
      onTap: () => _controller.selectItem(item),
      onDoubleTap: () => _showPropertiesDialog(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
            left: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            // Name Column (with Icon)
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  _buildAppIcon(item),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Publisher Column
            Expanded(
              flex: 3,
              child: Text(
                item.publisher,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),

            // Status Column (Enabled / Disabled)
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.isEnabled
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.isEnabled ? 'Enabled' : 'Disabled',
                    style: TextStyle(
                      color: item.isEnabled
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontSize: 13,
                      fontWeight:
                          item.isEnabled ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            // Startup Impact Column
            Expanded(
              flex: 2,
              child: Text(
                item.impactLabel,
                style: TextStyle(
                  color: item.impact == StartupImpact.high
                      ? AppColors.danger
                      : (item.impact == StartupImpact.medium
                          ? AppColors.warning
                          : AppColors.textSecondary),
                  fontSize: 12,
                  fontWeight: item.impact == StartupImpact.high
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),

            // Interactive Toggle Switch
            SizedBox(
              width: 60,
              child: Switch(
                key: ValueKey('switch_${item.id}'),
                value: item.isEnabled,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                inactiveThumbColor: AppColors.textMuted,
                inactiveTrackColor: AppColors.surfaceLight,
                onChanged: (val) async {
                  await _controller.toggleApp(item, val);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIcon(StartupAppItem item) {
    IconData iconData = Icons.apps_rounded;
    Color iconColor = AppColors.primary;

    final lower = item.name.toLowerCase();
    if (lower.contains('discord')) {
      iconData = Icons.chat_bubble_outline_rounded;
      iconColor = const Color(0xFF5865F2);
    } else if (lower.contains('steam')) {
      iconData = Icons.sports_esports_rounded;
      iconColor = const Color(0xFF171A21);
    } else if (lower.contains('chrome') ||
        lower.contains('edge') ||
        lower.contains('firefox')) {
      iconData = Icons.language_rounded;
      iconColor = AppColors.accent;
    } else if (lower.contains('security') || lower.contains('antidote')) {
      iconData = Icons.shield_rounded;
      iconColor = AppColors.primary;
    } else if (lower.contains('update')) {
      iconData = Icons.system_update_rounded;
      iconColor = AppColors.warning;
    } else if (item.locationType == 'UWP') {
      iconData = Icons.window_rounded;
      iconColor = AppColors.accent;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(iconData, size: 16, color: iconColor),
    );
  }
}
