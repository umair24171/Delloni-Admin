import 'package:delloniweb/controllers/notifications_provider.dart';
import 'package:delloniweb/screens/notiifications_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationCounterWidget extends StatelessWidget {
  const NotificationCounterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NotificationsProvider(),
      child: Consumer<NotificationsProvider>(
        builder: (context, provider, child) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.2), // ArabicTheme.warning
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFFFF9800), // ArabicTheme.warning
                    size: 24,
                  ),
                  if (provider.unreadCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF44336), // ArabicTheme.error
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF44336).withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              provider.unreadCount > 99 ? '99+' : '${provider.unreadCount}',
                              key: ValueKey(provider.unreadCount),
                              style: GoogleFonts.inter(
                                color: const Color(0xFFF1F8E9), // ArabicTheme.textLight
                                fontSize: provider.unreadCount > 99 ? 8 : 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
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
    );
  }
}
