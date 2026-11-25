import 'package:flutter/material.dart';
import 'package:antidotes/core/constants/app_colors.dart';
import 'package:antidotes/core/widgets/app_icon_widget.dart';
import 'package:antidotes/features/software_uninstaller/data/models/installed_app_item.dart';
import 'package:antidotes/features/software_uninstaller/presentation/controllers/software_uninstaller_controller.dart';
import 'package:antidotes/features/software_uninstaller/presentation/widgets/software_uninstall_wizard_dialog.dart';

class SoftwareUninstallerScreen extends StatefulWidget {
  final SoftwareUninstallerController? controller;

  const SoftwareUninstallerScreen({super.key, this.controller});

  @override
  State<SoftwareUninstallerScreen> createState() => _SoftwareUninstallerScreenState();
}

class _SoftwareUninstallerScreenState extends State<SoftwareUninstallerScreen> {
  late final SoftwareUninstallerController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? SoftwareUninstallerController();
    _controller.addListener(_onControllerUpdate);
    _controller.loadApps();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _openUninstallWizard(InstalledAppItem app) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SoftwareUninstallWizardDialog(
        app: app,
        service: _controller.service,
        onUninstallComplete: () {
          _controller.removeApp(app.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${app.name} was successfully uninstalled and traces cleaned.'),
              backgroundColor: Colors.green.shade800,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apps = _controller.filteredApps;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 16),

            // Top Stats Cards
            _buildStatsCards(),
            const SizedBox(height: 16),

            // Search Bar & Controls
            _buildSearchBar(),
            const SizedBox(height: 16),

            // Apps Table
            Expanded(
              child: _controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildAppsTable(apps),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Software Uninstaller',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Deeply uninstall applications, delete leftover registry keys, and purge residual files',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: _controller.loadApps,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh installed apps',
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    final card1 = _buildMetricCard(
      title: 'Installed Applications',
      value: '${_controller.totalCount} Apps',
      icon: Icons.apps_rounded,
      color: const Color(0xFF0288D1),
    );
    final card2 = _buildMetricCard(
      title: 'Estimated Disk Footprint',
      value: _controller.totalSizeFormatted,
      icon: Icons.pie_chart_rounded,
      color: const Color(0xFFF57C00),
    );
    final card3 = _buildMetricCard(
      title: 'Deep Clean Engine',
      value: 'Registry & File Trace Purge',
      icon: Icons.auto_delete_rounded,
      color: Colors.green,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Column(
            children: [
              card1,
              const SizedBox(height: 10),
              card2,
              const SizedBox(height: 10),
              card3,
            ],
          );
        } else if (constraints.maxWidth < 720) {
          return Column(
            children: [
              Row(children: [
                Expanded(child: card1),
                const SizedBox(width: 12),
                Expanded(child: card2),
              ]),
              const SizedBox(height: 10),
              card3,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: card1),
            const SizedBox(width: 14),
            Expanded(child: card2),
            const SizedBox(width: 14),
            Expanded(child: card3),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _controller.setSearchQuery,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search installed applications by name, publisher, or version...',
                hintStyle: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          _controller.setSearchQuery('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppsTable(List<InstalledAppItem> apps) {
    if (apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'No installed programs match your search.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, tableConstraints) {
        const double minTableWidth = 760.0;
        final tableWidth = tableConstraints.maxWidth < minTableWidth
            ? minTableWidth
            : tableConstraints.maxWidth;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildColumnHeader('Name', 'name'),
                        ),
                        Expanded(
                          flex: 3,
                          child: _buildColumnHeader('Publisher', 'publisher'),
                        ),
                        Expanded(
                          flex: 2,
                          child: _buildColumnHeader('Install Date', 'date'),
                        ),
                        Expanded(
                          flex: 2,
                          child: _buildColumnHeader('Size', 'size'),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Version',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'Action',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Rows
                  Expanded(
                    child: ListView.separated(
                      itemCount: apps.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: AppColors.surfaceBorder.withValues(alpha: 0.5)),
                      itemBuilder: (context, index) {
                        final app = apps[index];
                        return InkWell(
                          onTap: () => _openUninstallWizard(app),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                // Icon & Name
                                Expanded(
                                  flex: 5,
                                  child: Row(
                                    children: [
                                      AppIconWidget(
                                        name: app.name,
                                        iconPath: app.iconPath,
                                        iconCachePath: app.iconCachePath,
                                        fallbackIcon: app.defaultIcon,
                                        size: 32,
                                        borderRadius: 6,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          app.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Publisher
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    app.displayPublisher,
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Install Date
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    app.displayDate,
                                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ),
                                // Size
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    app.formattedSize,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                // Version
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    app.displayVersion,
                                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Uninstall Button
                                SizedBox(
                                  width: 100,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _openUninstallWizard(app),
                                      icon: const Icon(Icons.delete_outline_rounded, size: 14),
                                      label: const Text('Uninstall'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFD32F2F).withValues(alpha: 0.12),
                                        foregroundColor: const Color(0xFFE53935),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        elevation: 0,
                                        textStyle: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          side: BorderSide(
                                            color: const Color(0xFFE53935).withValues(alpha: 0.3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColumnHeader(String label, String columnKey) {
    final isSelected = _controller.sortColumn == columnKey;

    return InkWell(
      onTap: () => _controller.sortBy(columnKey),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 4),
          if (isSelected)
            Icon(
              _controller.isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 14,
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }
}
