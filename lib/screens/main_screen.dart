import 'package:flutter/material.dart';
import '../state/calendar_state.dart';
import '../widgets/educal_logo.dart';
import 'dashboard/dashboard_screen.dart';
import 'notices/notices_screen.dart';
import 'setup/setup_screen.dart';
import 'tools/tools_screen.dart';
import 'reminders/notification_dialog.dart';
import 'reminders/reminder_settings_dialog.dart';
import 'auth/student_login_dialog.dart';
import 'auth/gmail_profile_dialog.dart';
import '../services/app_update_service.dart';

class MainScreen extends StatefulWidget {
  final CalendarState state;

  const MainScreen({super.key, required this.state});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.checkForUpdates(context, isManual: false);
    });
  }

  @override
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state.removeListener(_onStateChange);
      widget.state.addListener(_onStateChange);
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openReminderSettings() {
    showDialog(
      context: context,
      builder: (ctx) => ReminderSettingsDialog(
        currentSettings: widget.state.reminderSettings,
        onSave: (newSettings) {
          widget.state.updateReminderSettings(newSettings);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminder preferences updated successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _openNotificationsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => NotificationDialog(
        notifications: widget.state.notifications,
        onMarkRead: (id) => widget.state.markNotificationRead(id),
        onMarkAllRead: () => widget.state.markAllNotificationsRead(),
        onOpenSettings: () {
          Navigator.of(ctx).pop();
          _openReminderSettings();
        },
      ),
    );
  }

  void _openAuthOrProfile() {
    if (widget.state.isLoggedIn) {
      showDialog(
        context: context,
        builder: (ctx) => GmailProfileDialog(state: widget.state),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => StudentLoginDialog(state: widget.state),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = widget.state.unreadNotificationCount;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: EduCalLogo(
            size: 32,
            isDark: isDark,
          ),
        ),
        actions: [
          // 3-Way Theme Mode Selector (Light, Dark, System)
          PopupMenuButton<ThemeMode>(
            icon: Icon(
              widget.state.themeMode == ThemeMode.system
                  ? Icons.brightness_auto_rounded
                  : (widget.state.themeMode == ThemeMode.dark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded),
              size: 20,
            ),
            tooltip: 'Select Theme Mode',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (mode) => widget.state.setThemeMode(mode),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: ThemeMode.light,
                child: Row(
                  children: [
                    const Icon(Icons.light_mode_rounded, size: 18, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 10),
                    const Text('Light Mode'),
                    if (widget.state.themeMode == ThemeMode.light) ...[
                      const Spacer(),
                      const Icon(Icons.check_rounded, size: 16, color: Color(0xFF3B82F6)),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: ThemeMode.dark,
                child: Row(
                  children: [
                    const Icon(Icons.dark_mode_rounded, size: 18, color: Color(0xFF8B5CF6)),
                    const SizedBox(width: 10),
                    const Text('Dark Mode'),
                    if (widget.state.themeMode == ThemeMode.dark) ...[
                      const Spacer(),
                      const Icon(Icons.check_rounded, size: 16, color: Color(0xFF3B82F6)),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: ThemeMode.system,
                child: Row(
                  children: [
                    const Icon(Icons.brightness_auto_rounded, size: 18, color: Color(0xFF10B981)),
                    const SizedBox(width: 10),
                    const Text('System Default'),
                    if (widget.state.themeMode == ThemeMode.system) ...[
                      const Spacer(),
                      const Icon(Icons.check_rounded, size: 16, color: Color(0xFF3B82F6)),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Notification Bell
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                onPressed: _openNotificationsDialog,
                tooltip: 'Reminders & Notifications',
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),

          // Check for App Updates action
          IconButton(
            icon: const Icon(Icons.system_update_alt_rounded, size: 21),
            tooltip: 'Check for Updates',
            onPressed: () => AppUpdateService.checkForUpdates(context, isManual: true),
          ),

          // University Account / Google Profile Avatar & Drive Sync Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: widget.state.isLoggedIn
                ? Tooltip(
                    message: '${widget.state.currentStudent!.email} (Google Drive Synced)',
                    child: InkWell(
                      onTap: _openAuthOrProfile,
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                widget.state.currentStudent!.avatarLetter,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Tooltip(
                    message: 'Login with University Gmail',
                    child: OutlinedButton(
                      onPressed: _openAuthOrProfile,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: const Color(0xFF2563EB).withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.network(
                            'https://www.gstatic.com/images/branding/product/1x/googleg_48dp.png',
                            width: 14,
                            height: 14,
                            errorBuilder: (_, __, ___) => const Icon(Icons.account_circle_outlined, size: 14, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: 4),
                          const Text('Login', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildCurrentTab(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.state.currentTabIndex,
        onDestinationSelected: (index) {
          widget.state.setTabIndex(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign_rounded),
            label: 'Academic Notices',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Class Setup',
          ),
          NavigationDestination(
            icon: Icon(Icons.construction_outlined),
            selectedIcon: Icon(Icons.construction_rounded),
            label: 'Tools',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (widget.state.currentTabIndex) {
      case 0:
        return DashboardScreen(state: widget.state);
      case 1:
        return NoticesScreen(state: widget.state);
      case 2:
        return SetupScreen(state: widget.state);
      case 3:
        return ToolsScreen(state: widget.state);
      default:
        return DashboardScreen(state: widget.state);
    }
  }
}
