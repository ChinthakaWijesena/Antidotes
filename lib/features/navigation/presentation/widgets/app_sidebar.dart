import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/nav_topic.dart';
import 'sidebar_footer.dart';
import 'sidebar_header.dart';
import 'sidebar_topic_tile.dart';
import 'sidebar_profile_tile.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';

/// Categorized, collapsible sidebar navigation for Antidotes.
/// Organizes tools into Topics (Sections) and Subtopics (Tools).
class AppSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final AuthController? authController;
  final ProfileController? profileController;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.authController,
    this.profileController,
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
    return Container(
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
          const SidebarHeader(),

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
}
