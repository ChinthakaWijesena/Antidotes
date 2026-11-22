import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/win32_shell_service.dart';
import '../../data/models/cleaner_safety_options.dart';

class SafetySettingsDialog extends StatefulWidget {
  final CleanerSafetyOptions initialOptions;
  final ValueChanged<CleanerSafetyOptions> onSaved;

  const SafetySettingsDialog({
    super.key,
    required this.initialOptions,
    required this.onSaved,
  });

  @override
  State<SafetySettingsDialog> createState() => _SafetySettingsDialogState();
}

class _SafetySettingsDialogState extends State<SafetySettingsDialog> {
  late CleanerSafetyOptions _options;
  final _excludeFolderController = TextEditingController();
  final _excludePatternController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _options = widget.initialOptions.clone();
  }

  @override
  void dispose() {
    _excludeFolderController.dispose();
    _excludePatternController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.surfaceBorder),
      ),
      child: Container(
        width: 600,
        height: 640,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.security_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Cleaner Safety & Rules',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Customize safeguard filters, exclusions, and file protection policies.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: [
                  // Safety switches
                  SwitchListTile(
                    title: const Text('Ignore files modified in last 24 hours'),
                    subtitle: Text(
                      'Recommended. Prevents deleting active cache files currently written by running software.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    value: _options.ignoreRecent24Hours,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _options.ignoreRecent24Hours = val),
                  ),
                  const Divider(),

                  SwitchListTile(
                    title: const Text('Send files to Windows Recycle Bin'),
                    subtitle: Text(
                      'Allows undoing deletions instead of permanent file removal (uses SHFileOperation).',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    value: _options.sendToRecycleBin,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _options.sendToRecycleBin = val),
                  ),
                  const Divider(),

                  SwitchListTile(
                    title: const Text('Include *.log files (Medium Risk)'),
                    subtitle: Text(
                      'Application logs. Some active services or developer tools use these.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    value: _options.includeLogs,
                    activeThumbColor: AppColors.warning,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _options.includeLogs = val),
                  ),
                  const Divider(),

                  SwitchListTile(
                    title: const Text('Include *.old & *.bak files (High Risk)'),
                    subtitle: const Text(
                      'Backup files created by editors or users. Keep disabled unless certain.',
                      style: TextStyle(fontSize: 12, color: AppColors.danger),
                    ),
                    value: _options.includeBackups,
                    activeThumbColor: AppColors.danger,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _options.includeBackups = val),
                  ),
                  const Divider(),

                  // Exclude Folders
                  const SizedBox(height: 8),
                  Text(
                    'Excluded Folders (Whitelist)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _excludeFolderController,
                          decoration: InputDecoration(
                            hintText: 'e.g. C:\\Users\\Name\\Desktop\\MyWork',
                            hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.surfaceBorder),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final text = _excludeFolderController.text.trim();
                          if (text.isNotEmpty && !_options.excludeFolders.contains(text)) {
                            setState(() {
                              _options.excludeFolders.add(text);
                              _excludeFolderController.clear();
                            });
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  if (_options.excludeFolders.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _options.excludeFolders
                          .map(
                            (folder) => Chip(
                              label: Text(folder, style: const TextStyle(fontSize: 11)),
                              backgroundColor: AppColors.surfaceLight,
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () {
                                setState(() => _options.excludeFolders.remove(folder));
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  // Exclude Patterns
                  const SizedBox(height: 16),
                  Text(
                    'Excluded File Patterns',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _excludePatternController,
                          decoration: InputDecoration(
                            hintText: 'e.g. *.keep, project_*.tmp',
                            hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.surfaceBorder),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final text = _excludePatternController.text.trim();
                          if (text.isNotEmpty && !_options.excludePatterns.contains(text)) {
                            setState(() {
                              _options.excludePatterns.add(text);
                              _excludePatternController.clear();
                            });
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  if (_options.excludePatterns.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _options.excludePatterns
                          .map(
                            (pattern) => Chip(
                              label: Text(pattern, style: const TextStyle(fontSize: 11)),
                              backgroundColor: AppColors.surfaceLight,
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () {
                                setState(() => _options.excludePatterns.remove(pattern));
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  // Windows.old & Disk Cleanup Link
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.accent, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Looking for Windows.old cleanup?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Windows.old should never be deleted manually. Launch Microsoft Disk Cleanup (cleanmgr) for safe removal.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => Win32ShellService.launchCleanmgr(),
                          child: const Text('Open cleanmgr'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    widget.onSaved(_options);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save Safety Rules'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
