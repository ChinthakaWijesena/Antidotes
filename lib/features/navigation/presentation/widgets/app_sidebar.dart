import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/nav_topic.dart';
import 'sidebar_footer.dart';
import 'sidebar_header.dart';
import 'sidebar_topic_tile.dart';
import 'sidebar_profile_tile.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

/// Categorized, collapsible sidebar navigation for Antidotes.
/// Organizes tools into Topics (Sections) and Subtopics (Tools).
/// Supports both full-width (255px) and compact icon rail (72px) modes for responsive layouts.
class AppSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final AuthController? authController;
  final ProfileController? profileController;
  final bool isCompact;
  final VoidCallback? onToggleCollapse;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.authController,
    this.profileController,
    this.isCompact = false,
    this.onToggleCollapse,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  late final Set<String> _expandedTopicIds;

  @override
  void initState() {
    super.initState();
    // Expand all categorized topics by default so users can easily see all sub-tools
    _expandedTopicIds = NavTopic.defaultTopics.map((t) => t.id).toSet();
  }

  @override
  void didUpdateWidget(covariant AppSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      // Ensure the topic containing the currently active subtopic is expanded
      final activeTopic = NavTopic.forIndex(widget.selectedIndex);
      if (activeTopic != null && !_expandedTopicIds.contains(activeTopic.id)) {
        setState(() {
          _expandedTopicIds.add(activeTopic.id);
        });
      }
    }
  }

  void _toggleTopic(String topicId) {
    setState(() {
      if (_expandedTopicIds.contains(topicId)) {
        _expandedTopicIds.remove(topicId);
      } else {
        _expandedTopicIds.add(topicId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactSidebar(context);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 255,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header Logo & Branding
          SidebarHeader(onToggleCollapse: widget.onToggleCollapse),

          // Scrollable Categorized Topics & Subtopics
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: NavTopic.defaultTopics.map((topic) {
                  return SidebarTopicTile(
                    topic: topic,
                    isExpanded: _expandedTopicIds.contains(topic.id),
                    selectedIndex: widget.selectedIndex,
                    onItemSelected: widget.onDestinationSelected,
                    onToggleExpand: () => _toggleTopic(topic.id),
                  );
                }).toList(),
              ),
            ),
          ),

          // User Profile Card & Cloud Sync
          SidebarProfileTile(
            authController: widget.authController,
            profileController: widget.profileController,
          ),

          // Real-time Protection Status Footer
          const SidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildCompactSidebar(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 72,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Compact App Icon
          Tooltip(
            message: 'Antidotes PC Optimizer',
            waitDuration: const Duration(milliseconds: 300),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/icons/app_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.shield_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Expand Sidebar Toggle Button
          if (widget.onToggleCollapse != null)
            IconButton(
              icon: const Icon(Icons.menu_rounded, size: 20),
              tooltip: 'Expand sidebar',
              color: AppColors.textMuted,
              onPressed: widget.onToggleCollapse,
              splashRadius: 18,
            ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Compact Nav Items List
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (int t = 0; t < NavTopic.defaultTopics.length; t++) ...[
                    if (t > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Container(
                          width: 24,
                          height: 1,
                          color: AppColors.surfaceBorder,
                        ),
                      ),
                    for (final item in NavTopic.defaultTopics[t].items)
                      _buildCompactNavItem(item),
                  ],
                ],
              ),
            ),
          ),

          // Compact User Profile
          _buildCompactProfileTile(context),

          // Compact Protection Status
          Tooltip(
            message: 'Protection Active\nSafe Clean Engine v1.0',
            waitDuration: const Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactNavItem(dynamic item) {
    final isSelected = item.index == widget.selectedIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Tooltip(
        message: item.label,
        waitDuration: const Duration(milliseconds: 250),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => widget.onDestinationSelected(item.index),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 1.2,
              ),
            ),
            child: Center(
              child: Icon(
                item.icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactProfileTile(BuildContext context) {
    if (widget.authController == null || widget.profileController == null) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: Listenable.merge(
          [widget.authController!, widget.profileController!]),
      builder: (context, _) {
        final user = widget.authController!.currentUser;
        final profile = widget.profileController!.profile;
        final isAuth = widget.authController!.isAuthenticated;
        final displayName =
            profile?.displayName ?? user?.displayName ?? 'Guest User';
        final initials = user?.initials ?? 'G';

        return Tooltip(
          message: displayName,
          waitDuration: const Duration(milliseconds: 300),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              ProfileScreen.show(
                context,
                authController: widget.authController!,
                profileController: widget.profileController!,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: isAuth ? AppColors.success : AppColors.warning,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 1.5,
                        ),
                      ),
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
}
