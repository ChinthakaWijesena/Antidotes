import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../core/platform/process_platform_service.dart';
import '../../data/models/game_model.dart';

/// Modal dialog for adding or configuring a game's boost parameters.
class AddGameDialog extends StatefulWidget {
  final Game? existingGame;
  final Future<Map<String, String>?> Function() onPickExe;
  final void Function(Game game) onSave;

  const AddGameDialog({
    super.key,
    this.existingGame,
    required this.onPickExe,
    required this.onSave,
  });

  @override
  State<AddGameDialog> createState() => _AddGameDialogState();
}

class _AddGameDialogState extends State<AddGameDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _pathController;
  String? _iconCachePath;

  late bool _autoBoost;
  late bool _switchPowerPlan;
  late bool _closeBackgroundApps;
  late bool _raisePriority;
  late bool _cleanTemp;
  late ProcessPriority _priority;

  @override
  void initState() {
    super.initState();
    final g = widget.existingGame;
    _nameController = TextEditingController(text: g?.name ?? '');
    _pathController = TextEditingController(text: g?.exePath ?? '');
    _iconCachePath = g?.iconCachePath;

    _autoBoost = g?.autoBoost ?? true;
    _switchPowerPlan = g?.switchPowerPlan ?? true;
    _closeBackgroundApps = g?.closeBackgroundApps ?? true;
    _raisePriority = g?.raisePriority ?? true;
    _cleanTemp = g?.cleanTemp ?? false;
    _priority = g?.targetPriority ?? ProcessPriority.aboveNormal;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _handleBrowse() async {
    final result = await widget.onPickExe();
    if (result != null) {
      setState(() {
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = result['name'] ?? '';
        }
        _pathController.text = result['exePath'] ?? '';
        _iconCachePath = result['iconCachePath'];
      });
    }
  }

  void _submit() {
    final name = _nameController.text.trim();
    final path = _pathController.text.trim();
    if (name.isEmpty || path.isEmpty) return;

    final game = Game(
      id: widget.existingGame?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      exePath: path,
      iconCachePath: _iconCachePath,
      autoBoost: _autoBoost,
      switchPowerPlan: _switchPowerPlan,
      closeBackgroundApps: _closeBackgroundApps,
      raisePriority: _raisePriority,
      cleanTemp: _cleanTemp,
      targetPriority: _priority,
      appsToClose: widget.existingGame?.appsToClose ?? const [],
    );

    widget.onSave(game);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingGame != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.surfaceBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sports_esports_rounded, color: AppColors.accent, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'Configure Game Boost' : 'Add Game to Library',
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
              const SizedBox(height: 16),
              // Executable Path
              Text('GAME EXECUTABLE', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pathController,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: r'C:\Games\Example\game.exe',
                        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.surfaceBorder)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _handleBrowse,
                    icon: const Icon(Icons.folder_open_rounded, size: 16),
                    label: const Text('Browse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Name
              Text('DISPLAY NAME', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Enter Game Title',
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.surfaceBorder)),
                ),
              ),
              const SizedBox(height: 16),
              Text('BOOST ACTIONS', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // Options Checkboxes
              _buildSwitchTile('Auto-Boost on detection', 'Boost automatically when game process is detected running', _autoBoost, (v) => setState(() => _autoBoost = v)),
              _buildSwitchTile('Switch Power Plan to High Performance', 'Restores previous Windows plan when game exits', _switchPowerPlan, (v) => setState(() => _switchPowerPlan = v)),
              _buildSwitchTile('Raise Process Priority', 'Elevates CPU core scheduling preference (Never Realtime)', _raisePriority, (v) => setState(() => _raisePriority = v)),
              _buildSwitchTile('Close Selected Background Apps', 'Frees RAM and background CPU usage during game session', _closeBackgroundApps, (v) => setState(() => _closeBackgroundApps = v)),
              _buildSwitchTile('Clean Temporary Files (%TEMP%)', 'Purges cache files older than 24h prior to launch', _cleanTemp, (v) => setState(() => _cleanTemp = v)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(isEdit ? 'Save Changes' : 'Add Game'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}
