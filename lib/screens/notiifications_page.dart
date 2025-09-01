import 'package:delloniweb/controllers/notifications_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NotificationsProvider(),
      child: Scaffold(
        backgroundColor: const Color(0xFF081C15), // ArabicTheme.backgroundDark
        appBar: _buildAppBar(),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(child: _buildNotificationsContent()),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1B4332), // ArabicTheme.primaryGreen
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back,
          color: Color(0xFFF1F8E9), // ArabicTheme.textLight
        ),
      ),
      title: Text(
        'Notifications',
        style: GoogleFonts.inter(
          color: const Color(0xFFF1F8E9),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        Consumer<NotificationsProvider>(
          builder: (context, provider, child) {
            return PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'mark_all_read':
                    await provider.markAllAsRead();
                    break;
                  case 'clear_all':
                    _showClearAllDialog(provider);
                    break;
                  case 'refresh':
                    await provider.refreshNotifications();
                    break;
                }
              },
              icon: const Icon(
                Icons.more_vert,
                color: Color(0xFFF1F8E9),
              ),
              color: const Color(0xFF1B4332),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mark_email_read_outlined,
                        size: 18,
                        color: Color(0xFF52B788),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Mark all as read',
                        style: GoogleFonts.inter(color: const Color(0xFFF1F8E9)),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.refresh,
                        size: 18,
                        color: Color(0xFF2196F3),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Refresh',
                        style: GoogleFonts.inter(color: const Color(0xFFF1F8E9)),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.clear_all,
                        size: 18,
                        color: Color(0xFFF44336),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Clear all',
                        style: GoogleFonts.inter(color: const Color(0xFFF44336)),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B4332), // ArabicTheme.primaryGreen
            const Color(0xFF2D5016), // ArabicTheme.mediumGreen
          ],
        ),
      ),
      child: Consumer<NotificationsProvider>(
        builder: (context, provider, child) {
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF52B788).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: Color(0xFF52B788),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Center',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF1F8E9),
                      ),
                    ),
                    Text(
                      '${provider.notifications.length} total, ${provider.unreadCount} unread',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFFC8E6C9),
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF44336), // ArabicTheme.error
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF44336).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '${provider.unreadCount}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFF1F8E9),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF2D5016)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF52B788),
        indicatorWeight: 3,
        labelColor: const Color(0xFF52B788),
        unselectedLabelColor: const Color(0xFFC8E6C9),
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.notifications_outlined, size: 20),
                const SizedBox(width: 8),
                const Text('All'),
                Consumer<NotificationsProvider>(
                  builder: (context, provider, child) {
                    final count = provider.notifications.length;
                    return count > 0
                        ? Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF52B788),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF081C15),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mark_email_unread_outlined, size: 20),
                const SizedBox(width: 8),
                const Text('Unread'),
                Consumer<NotificationsProvider>(
                  builder: (context, provider, child) {
                    final count = provider.unreadCount;
                    return count > 0
                        ? Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF44336),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFF1F8E9),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsContent() {
    return Container(
      color: const Color(0xFF081C15),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildAllNotificationsTab(),
          _buildUnreadNotificationsTab(),
        ],
      ),
    );
  }

  Widget _buildAllNotificationsTab() {
    return Consumer<NotificationsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildLoadingWidget();
        }

        if (provider.error != null) {
          return _buildErrorWidget(provider.error!);
        }

        if (provider.notifications.isEmpty) {
          return _buildEmptyWidget(
            'No notifications yet',
            'New notifications will appear here',
            Icons.notifications_outlined,
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.refreshNotifications(),
          backgroundColor: const Color(0xFF1B4332),
          color: const Color(0xFF52B788),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return _buildNotificationTile(notification, provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildUnreadNotificationsTab() {
    return Consumer<NotificationsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildLoadingWidget();
        }

        final unreadNotifications = provider.unreadNotifications;

        if (unreadNotifications.isEmpty) {
          return _buildEmptyWidget(
            'All caught up!',
            'No unread notifications',
            Icons.mark_email_read_outlined,
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.refreshNotifications(),
          backgroundColor: const Color(0xFF1B4332),
          color: const Color(0xFF52B788),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: unreadNotifications.length,
            itemBuilder: (context, index) {
              final notification = unreadNotifications[index];
              return _buildNotificationTile(notification, provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationTile(NotificationModel notification, NotificationsProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead 
              ? const Color(0xFF2D5016)
              : notification.priorityColor.withOpacity(0.5),
          width: notification.isRead ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Dismissible(
        key: Key(notification.id),
        background: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF52B788),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: Row(
            children: [
              const Icon(Icons.mark_email_read, color: Color(0xFFF1F8E9)),
              const SizedBox(width: 8),
              Text(
                'Mark as read',
                style: GoogleFonts.inter(
                  color: const Color(0xFFF1F8E9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF44336),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Delete',
                style: GoogleFonts.inter(
                  color: const Color(0xFFF1F8E9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.delete, color: Color(0xFFF1F8E9)),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Mark as read
            if (!notification.isRead) {
              await provider.markAsRead(notification.id);
            }
            return false;
          } else {
            // Delete
            return await _showDeleteConfirmation();
          }
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            provider.deleteNotification(notification.id);
          }
        },
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: notification.priorityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              notification.icon,
              color: notification.priorityColor,
              size: 24,
            ),
          ),
          title: Row(
            children: [
                Expanded(
                child: Text(
                  notification.title,
                  style: GoogleFonts.inter(
                  fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                  color: notification.isRead
                    ? const Color(0xFFC8E6C9)
                    : notification.priorityColor,
                  fontSize: 16,
                  ),
                ),
                ),
                if (!notification.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                  color: notification.priorityColor,
                  shape: BoxShape.circle,
                  ),
                ),
              ],
              ),
              subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                notification.body,
                style: GoogleFonts.inter(
                  color: const Color(0xFFF1F8E9),
                  fontSize: 14,
                ),
                ),
                const SizedBox(height: 8),
                Text(
                notification.timeAgo,
                style: GoogleFonts.inter(
                  color: const Color(0xFFB2DFDB),
                  fontSize: 12,
                ),
                ),
              ],
              ),
              trailing: notification.isRead
                ? null
                : IconButton(
                  icon: const Icon(Icons.mark_email_read_outlined, color: Color(0xFF52B788)),
                  tooltip: 'Mark as read',
                  onPressed: () => provider.markAsRead(notification.id),
                ),
            ),
            ),
          );
          }

          Widget _buildLoadingWidget() {
          return const Center(
            child: CircularProgressIndicator(
            color: Color(0xFF52B788),
            ),
          );
          }

          Widget _buildErrorWidget(String error) {
          return Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFF44336), size: 48),
              const SizedBox(height: 16),
              Text(
              'Error loading notifications',
              style: GoogleFonts.inter(
                color: const Color(0xFFF44336),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              ),
              const SizedBox(height: 8),
              Text(
              error,
              style: GoogleFonts.inter(
                color: const Color(0xFFF1F8E9),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF52B788),
                foregroundColor: const Color(0xFF081C15),
              ),
              onPressed: () {
                final provider = Provider.of<NotificationsProvider>(context, listen: false);
                provider.refreshNotifications();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              ),
            ],
            ),
          );
          }

          Widget _buildEmptyWidget(String title, String subtitle, IconData icon) {
          return Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF52B788), size: 56),
              const SizedBox(height: 16),
              Text(
              title,
              style: GoogleFonts.inter(
                color: const Color(0xFFF1F8E9),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              ),
              const SizedBox(height: 8),
              Text(
              subtitle,
              style: GoogleFonts.inter(
                color: const Color(0xFFC8E6C9),
                fontSize: 14,
              ),
              ),
            ],
            ),
          );
          }

          Future<bool> _showDeleteConfirmation() async {
          return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1B4332),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Delete Notification',
                style: GoogleFonts.inter(
                color: const Color(0xFFF44336),
                fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Are you sure you want to delete this notification?',
                style: GoogleFonts.inter(color: const Color(0xFFF1F8E9)),
              ),
              actions: [
                TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: const Color(0xFF52B788)),
                ),
                ),
                TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Delete',
                  style: GoogleFonts.inter(color: const Color(0xFFF44336)),
                ),
                ),
              ],
              ),
            ) ??
            false;
          }

          void _showClearAllDialog(NotificationsProvider provider) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1B4332),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Clear All Notifications',
              style: GoogleFonts.inter(
              color: const Color(0xFFF44336),
              fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to clear all notifications? This action cannot be undone.',
              style: GoogleFonts.inter(color: const Color(0xFFF1F8E9)),
            ),
            actions: [
              TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: const Color(0xFF52B788)),
              ),
              ),
              TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await provider.clearAllNotifications();
              },
              child: Text(
                'Clear All',
                style: GoogleFonts.inter(color: const Color(0xFFF44336)),
              ),
              ),
            ],
            ),
          );
          }
        }