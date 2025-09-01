import 'package:delloniweb/controllers/admin_chat_provider.dart';
import 'package:delloniweb/screens/admin_indiividual_chat.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({Key? key}) : super(key: key);

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminChatProvider>(context, listen: false).initializeChats();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildTabBar(),
          Expanded(child: _buildChatContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF00FF88).withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF88).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: Color(0xFF00FF88),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Chat Center',
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Manage conversations with users',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const Spacer(),
          Consumer<AdminChatProvider>(
            builder: (context, provider, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00FF88),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${provider.getTotalUnreadCount()} unread',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF00FF88),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          Provider.of<AdminChatProvider>(context, listen: false).searchChats(value);
        },
        style: GoogleFonts.cairo(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search users, messages, or products...',
          hintStyle: GoogleFonts.cairo(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF00FF88)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    Provider.of<AdminChatProvider>(context, listen: false).searchChats('');
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[800]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[800]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00FF88)),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF00FF88),
        indicatorWeight: 3,
        labelColor: const Color(0xFF00FF88),
        unselectedLabelColor: Colors.grey[400],
        labelStyle: GoogleFonts.cairo(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        unselectedLabelStyle: GoogleFonts.cairo(
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 20),
                const SizedBox(width: 8),
                const Text('All Chats'),
                Consumer<AdminChatProvider>(
                  builder: (context, provider, child) {
                    final count = provider.allChats.length;
                    return count > 0
                        ? Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF88),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: GoogleFonts.cairo(
                                color: Colors.black,
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
                const Icon(Icons.person_outline, size: 20),
                const SizedBox(width: 8),
                const Text('All Users'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.support_agent, size: 20),
                const SizedBox(width: 8),
                const Text('Support'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllChatsTab(),
        _buildAllUsersTab(),
        _buildSupportTab(),
      ],
    );
  }

  Widget _buildAllChatsTab() {
    return Consumer<AdminChatProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildLoadingWidget();
        }

        if (provider.error != null) {
          return _buildErrorWidget(provider.error!);
        }

        if (provider.currentChats.isEmpty) {
          return _buildEmptyWidget('No conversations yet', 'Start chatting with users to see conversations here');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.currentChats.length,
          itemBuilder: (context, index) {
            final chat = provider.currentChats[index];
            return _buildChatTile(chat);
          },
        );
      },
    );
  }

  Widget _buildAllUsersTab() {
    return Consumer<AdminChatProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildLoadingWidget();
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('uid', isNotEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingWidget();
            }

            if (snapshot.hasError) {
              return _buildErrorWidget('Error loading users: ${snapshot.error}');
            }

            final users = snapshot.data?.docs ?? [];
            final filteredUsers = users.where((doc) {
              final userData = doc.data() as Map<String, dynamic>;
              final name = userData['companyName'] ?? userData['name'] ?? '';
              final email = userData['email'] ?? '';
              return name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                     email.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();

            if (filteredUsers.isEmpty) {
              return _buildEmptyWidget('No users found', 'Try adjusting your search criteria');
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final userDoc = filteredUsers[index];
                final userData = userDoc.data() as Map<String, dynamic>;
                return _buildUserTile(userData);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSupportTab() {
    return Consumer<AdminChatProvider>(
      builder: (context, provider, child) {
        final supportChats = provider.allChats.where((chat) =>
            chat.chatType == 'support' || 
            chat.lastMessage.toLowerCase().contains('help') ||
            chat.lastMessage.toLowerCase().contains('support')
        ).toList();

        if (supportChats.isEmpty) {
          return _buildEmptyWidget('No support requests', 'Support conversations will appear here');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: supportChats.length,
          itemBuilder: (context, index) {
            final chat = supportChats[index];
            return _buildChatTile(chat, isSupport: true);
          },
        );
      },
    );
  }

  Widget _buildChatTile(chat, {bool isSupport = false}) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final otherUserName = chat.getOtherParticipantName(currentUser.uid);
    final unreadCount = chat.getUnreadCount(currentUser.uid);
    final lastMessageTime = chat.lastMessageTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSupport 
              ? const Color(0xFFFF6B35).withOpacity(0.3)
              : Colors.grey[800]!,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isSupport 
                  ? const Color(0xFFFF6B35).withOpacity(0.2)
                  : const Color(0xFF00FF88).withOpacity(0.2),
              child: Text(
                otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : 'U',
                style: GoogleFonts.cairo(
                  color: isSupport ? const Color(0xFFFF6B35) : const Color(0xFF00FF88),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            if (isSupport)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherUserName,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (lastMessageTime != null)
              Text(
                _formatTime(lastMessageTime),
                style: GoogleFonts.cairo(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chat.productTitle != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  chat.productTitle!,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF00FF88),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    chat.lastMessage.isEmpty ? 'No messages yet' : chat.lastMessage,
                    style: GoogleFonts.cairo(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF88),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: GoogleFonts.cairo(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminIndividualChatScreen(chatId: chat.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> userData) {
    final userName = userData['companyName'] ?? userData['name'] ?? 'Unknown User';
    final userEmail = userData['email'] ?? '';
    final userType = userData['type'] ?? 'individual';
    final profileImage = userData['profileImage'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: userType == 'company' 
              ? const Color(0xFF4A90E2).withOpacity(0.2)
              : const Color(0xFF00FF88).withOpacity(0.2),
          backgroundImage: profileImage != null ? NetworkImage(profileImage) : null,
          child: profileImage == null
              ? Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: GoogleFonts.cairo(
                    color: userType == 'company' ? const Color(0xFF4A90E2) : const Color(0xFF00FF88),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                userName,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: userType == 'company' 
                    ? const Color(0xFF4A90E2).withOpacity(0.2)
                    : const Color(0xFF00FF88).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                userType.toUpperCase(),
                style: GoogleFonts.cairo(
                  color: userType == 'company' ? const Color(0xFF4A90E2) : const Color(0xFF00FF88),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          userEmail,
          style: GoogleFonts.cairo(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          onPressed: () async {
            await _startChatWithUser(userData);
          },
          icon: const Icon(
            Icons.chat_bubble_outline,
            color: Color(0xFF00FF88),
          ),
        ),
      ),
    );
  }

  Future<void> _startChatWithUser(Map<String, dynamic> userData) async {
    try {
      final chatId = await Provider.of<AdminChatProvider>(context, listen: false)
          .createOrGetChatWithUser(
        otherUserId: userData['uid'],
        otherUserName: userData['companyName'] ?? userData['name'] ?? 'Unknown User',
        otherUserImage: userData['profileImage'],
      );

      if (chatId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminIndividualChatScreen(chatId: chatId),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Provider.of<AdminChatProvider>(context, listen: false).refreshChats();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF88),
              foregroundColor: Colors.black,
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}