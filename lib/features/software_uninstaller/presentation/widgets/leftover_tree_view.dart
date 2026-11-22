import 'package:flutter/material.dart';
import 'package:antidotes/core/constants/app_colors.dart';
import 'package:antidotes/features/software_uninstaller/data/models/leftover_item.dart';

class LeftoverTreeView extends StatefulWidget {
  final List<LeftoverItem> items;
  final ValueChanged<String> onPathSelected;
  final VoidCallback onItemToggled;

  const LeftoverTreeView({
    super.key,
    required this.items,
    required this.onPathSelected,
    required this.onItemToggled,
  });

  @override
  State<LeftoverTreeView> createState() => _LeftoverTreeViewState();
}

class _LeftoverTreeViewState extends State<LeftoverTreeView> {
  final Set<String> _expandedNodes = {'root', 'hkcu', 'hklm', 'files'};

  void _toggleExpanded(String key) {
    setState(() {
      if (_expandedNodes.contains(key)) {
        _expandedNodes.remove(key);
      } else {
        _expandedNodes.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final regItems = widget.items.where((i) => i.isRegistry).toList();
    final fileItems = widget.items.where((i) => !i.isRegistry).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        children: [
          // Root: My Computer
          _buildNodeRow(
            key: 'root',
            label: 'My Computer',
            icon: Icons.computer_rounded,
            iconColor: const Color(0xFF2979FF),
            depth: 0,
            hasChildren: true,
            isExpanded: _expandedNodes.contains('root'),
            onTap: () {
              _toggleExpanded('root');
              widget.onPathSelected('My Computer');
            },
          ),

          if (_expandedNodes.contains('root')) ...[
            // HKEY_CURRENT_USER Branch
            if (regItems.any((i) => i.rootKey.contains('CURRENT_USER'))) ...[
              _buildNodeRow(
                key: 'hkcu',
                label: 'HKEY_CURRENT_USER',
                icon: Icons.app_registration_rounded,
                iconColor: const Color(0xFFE53935),
                depth: 1,
                hasChildren: true,
                isExpanded: _expandedNodes.contains('hkcu'),
                onTap: () {
                  _toggleExpanded('hkcu');
                  widget.onPathSelected('HKEY_CURRENT_USER');
                },
              ),
              if (_expandedNodes.contains('hkcu')) ...[
                // Software subkey
                _buildNodeRow(
                  key: 'hkcu_software',
                  label: 'Software',
                  icon: Icons.folder_rounded,
                  iconColor: const Color(0xFFFFB300),
                  depth: 2,
                  hasChildren: true,
                  isExpanded: true,
                  onTap: () => widget.onPathSelected(r'HKEY_CURRENT_USER\Software'),
                ),
                // Children of HKCU
                ...regItems
                    .where((i) => i.rootKey.contains('CURRENT_USER'))
                    .map((item) => _buildItemRow(item, depth: 3)),
              ],
            ],

            // HKEY_LOCAL_MACHINE Branch
            if (regItems.any((i) => i.rootKey.contains('LOCAL_MACHINE'))) ...[
              _buildNodeRow(
                key: 'hklm',
                label: 'HKEY_LOCAL_MACHINE',
                icon: Icons.app_registration_rounded,
                iconColor: const Color(0xFFE53935),
                depth: 1,
                hasChildren: true,
                isExpanded: _expandedNodes.contains('hklm'),
                onTap: () {
                  _toggleExpanded('hklm');
                  widget.onPathSelected('HKEY_LOCAL_MACHINE');
                },
              ),
              if (_expandedNodes.contains('hklm')) ...[
                _buildNodeRow(
                  key: 'hklm_software',
                  label: 'Software',
                  icon: Icons.folder_rounded,
                  iconColor: const Color(0xFFFFB300),
                  depth: 2,
                  hasChildren: true,
                  isExpanded: true,
                  onTap: () => widget.onPathSelected(r'HKEY_LOCAL_MACHINE\Software'),
                ),
                ...regItems
                    .where((i) => i.rootKey.contains('LOCAL_MACHINE'))
                    .map((item) => _buildItemRow(item, depth: 3)),
              ],
            ],

            // File System Branch
            if (fileItems.isNotEmpty) ...[
              _buildNodeRow(
                key: 'files',
                label: 'Leftover Files & AppData Folders',
                icon: Icons.folder_special_rounded,
                iconColor: const Color(0xFF43A047),
                depth: 1,
                hasChildren: true,
                isExpanded: _expandedNodes.contains('files'),
                onTap: () {
                  _toggleExpanded('files');
                  widget.onPathSelected('File System Leftovers');
                },
              ),
              if (_expandedNodes.contains('files')) ...[
                ...fileItems.map((item) => _buildItemRow(item, depth: 2)),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildNodeRow({
    required String key,
    required String label,
    required IconData icon,
    required Color iconColor,
    required int depth,
    required bool hasChildren,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: EdgeInsets.only(left: depth * 18.0, top: 3, bottom: 3),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.arrow_drop_down_rounded : Icons.arrow_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: depth <= 1 ? FontWeight.w600 : FontWeight.w500,
                color: depth == 1 && label.startsWith('HKEY')
                    ? const Color(0xFFE53935)
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(LeftoverItem item, {required int depth}) {
    final isDeleted = item.isDeleted;

    return InkWell(
      onTap: () {
        widget.onPathSelected(item.path);
        if (!isDeleted) {
          setState(() {
            item.isSelected = !item.isSelected;
          });
          widget.onItemToggled();
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: EdgeInsets.only(left: depth * 18.0 + 16, top: 2, bottom: 2),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: item.isSelected && !isDeleted,
                onChanged: isDeleted
                    ? null
                    : (val) {
                        setState(() {
                          item.isSelected = val ?? false;
                        });
                        widget.onItemToggled();
                      },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              item.isRegistry
                  ? (item.type == LeftoverType.registryValue
                      ? Icons.description_outlined
                      : Icons.folder_open_rounded)
                  : Icons.insert_drive_file_outlined,
              size: 15,
              color: isDeleted ? AppColors.textMuted : const Color(0xFF0288D1),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 11.5,
                  decoration: isDeleted ? TextDecoration.lineThrough : null,
                  color: isDeleted ? AppColors.textMuted : AppColors.textPrimary,
                  fontFamily: 'Consolas',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isDeleted)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'Deleted',
                  style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
