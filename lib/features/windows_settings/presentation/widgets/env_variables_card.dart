import 'package:flutter/material.dart';
import 'package:antidotes/core/constants/app_colors.dart';
import 'package:antidotes/features/windows_settings/data/models/env_variable_item.dart';

class EnvVariablesCard extends StatelessWidget {
  final List<EnvVariableItem> variables;
  final String searchQuery;
  final int filterTab;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<EnvVariableItem> onSaveVariable;
  final Function(String name, bool isSystem) onDeleteVariable;
  final VoidCallback onOpenNativeEnv;

  const EnvVariablesCard({
    super.key,
    required this.variables,
    required this.searchQuery,
    required this.filterTab,
    required this.onSearchChanged,
    required this.onTabChanged,
    required this.onSaveVariable,
    required this.onDeleteVariable,
    required this.onOpenNativeEnv,
  });

  void _showAddEditDialog(BuildContext context, [EnvVariableItem? existing]) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final valController = TextEditingController(text: existing?.value ?? '');
    bool isSystem = existing?.isSystem ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Text(
            existing == null ? 'Add Environment Variable' : 'Edit Environment Variable',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Variable Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                TextField(
                  controller: nameController,
                  enabled: existing == null,
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Consolas'),
                  decoration: InputDecoration(
                    hintText: 'e.g. JAVA_HOME',
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: AppColors.surfaceBorder)),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Variable Value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                TextField(
                  controller: valController,
                  maxLines: 2,
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Consolas'),
                  decoration: InputDecoration(
                    hintText: 'e.g. C:\\Program Files\\Java\\jdk-21',
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: AppColors.surfaceBorder)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Scope: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: existing != null ? null : () => setState(() => isSystem = false),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: !isSystem ? AppColors.primary : AppColors.textMuted, width: 1.5),
                            ),
                            child: !isSystem
                                ? Center(child: Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary)))
                                : null,
                          ),
                          const SizedBox(width: 6),
                          const Text('User Variable', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    InkWell(
                      onTap: existing != null ? null : () => setState(() => isSystem = true),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: isSystem ? AppColors.primary : AppColors.textMuted, width: 1.5),
                            ),
                            child: isSystem
                                ? Center(child: Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary)))
                                : null,
                          ),
                          const SizedBox(width: 6),
                          const Text('System Variable', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final val = valController.text.trim();
                if (name.isNotEmpty) {
                  onSaveVariable(EnvVariableItem(name: name, value: val, isSystem: isSystem));
                  Navigator.of(ctx).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3F51B5).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.code_rounded, color: Color(0xFF3F51B5), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Windows Environment Variables (User & System)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Inspect, add, modify, or delete Path, System variables & SDK locations',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Variable'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onOpenNativeEnv,
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('Native Window'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.surfaceBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search & Filter Tabs
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: TextField(
                    onChanged: onSearchChanged,
                    style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search variables by name or value...',
                      hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.search_rounded, size: 16, color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              _buildFilterTab(0, 'All (${variables.length})'),
              const SizedBox(width: 6),
              _buildFilterTab(1, 'User Variables'),
              const SizedBox(width: 6),
              _buildFilterTab(2, 'System Variables'),
            ],
          ),
          const SizedBox(height: 12),

          // Variables Table
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: variables.isEmpty
                ? Center(
                    child: Text(
                      'No environment variables found matching the search.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    itemCount: variables.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: AppColors.surfaceBorder.withValues(alpha: 0.5)),
                    itemBuilder: (context, index) {
                      final item = variables[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.isSystem
                                    ? const Color(0xFFF57C00).withValues(alpha: 0.15)
                                    : const Color(0xFF0288D1).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.isSystem ? 'SYSTEM' : 'USER',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: item.isSystem ? const Color(0xFFF57C00) : const Color(0xFF0288D1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 160,
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Consolas',
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.value,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Consolas',
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              tooltip: 'Edit Variable',
                              color: AppColors.textMuted,
                              onPressed: () => _showAddEditDialog(context, item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16),
                              tooltip: 'Delete Variable',
                              color: Colors.red.shade400,
                              onPressed: () => onDeleteVariable(item.name, item.isSystem),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(int tabIndex, String label) {
    final isSelected = filterTab == tabIndex;
    return InkWell(
      onTap: () => onTabChanged(tabIndex),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
