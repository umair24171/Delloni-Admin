import 'package:delloniweb/controllers/individual_chat_provider.dart';
import 'package:delloniweb/model/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:html' as html;
class AdminIndividualChatScreen extends StatefulWidget {
  final String chatId;

  const AdminIndividualChatScreen({
    Key? key,
    required this.chatId,
  }) : super(key: key);

  @override
  State<AdminIndividualChatScreen> createState() => _AdminIndividualChatScreenState();
}

class _AdminIndividualChatScreenState extends State<AdminIndividualChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AdminIndividualChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    _chatProvider = AdminIndividualChatProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProvider.initializeChat(widget.chatId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _chatProvider,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessagesArea()),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF00FF88).withOpacity(0.2)),
        ),
      ),
      child: Consumer<AdminIndividualChatProvider>(
        builder: (context, provider, child) {
          final chat = provider.chat;
          final otherParticipant = provider.otherParticipant;

          if (chat == null) {
            return Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
                    ),
                  ),
                ),
              ],
            );
          }

          final currentUser = FirebaseAuth.instance.currentUser;
          final otherUserName = chat.getOtherParticipantName(currentUser?.uid ?? '');

          return Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF00FF88).withOpacity(0.2),
                backgroundImage: otherParticipant?.profileImage != null
                    ? NetworkImage(otherParticipant!.profileImage!)
                    : null,
                child: otherParticipant?.profileImage == null
                    ? Text(
                        otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : 'U',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF00FF88),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUserName,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (chat.productTitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Product: ${chat.productTitle}',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF00FF88),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (provider.otherUserTyping)
                      Text(
                        'typing...',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF00FF88),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              _buildHeaderActions(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderActions(AdminIndividualChatProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _showChatOptions(provider),
          icon: const Icon(Icons.more_vert, color: Colors.white),
        ),
      ],
    );
  }

  void _showChatOptions(AdminIndividualChatProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chat Options',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.block,
              title: 'Block User',
              subtitle: 'Block this user from messaging',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showBlockConfirmation(provider);
              },
            ),
            _buildOptionTile(
              icon: Icons.archive,
              title: 'Archive Chat',
              subtitle: 'Archive this conversation',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                provider.archiveChat(widget.chatId);
              },
            ),
            _buildOptionTile(
              icon: Icons.delete,
              title: 'Delete Chat',
              subtitle: 'Permanently delete this conversation',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: GoogleFonts.cairo(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.cairo(color: Colors.grey[400]),
      ),
      onTap: onTap,
    );
  }

  void _showBlockConfirmation(AdminIndividualChatProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Block User',
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to block this user? They won\'t be able to message you.',
          style: GoogleFonts.cairo(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.cairo(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement block user logic
            },
            child: Text(
              'Block',
              style: GoogleFonts.cairo(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(AdminIndividualChatProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Delete Chat',
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
          style: GoogleFonts.cairo(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.cairo(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteChat(widget.chatId);
              Navigator.pop(context); // Go back to chat list
            },
            child: Text(
              'Delete',
              style: GoogleFonts.cairo(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesArea() {
    return Consumer<AdminIndividualChatProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
            ),
          );
        }

        if (provider.error != null) {
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
                  'Error loading messages',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  style: GoogleFonts.cairo(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (provider.messages.isEmpty) {
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
                  'No messages yet',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start the conversation by sending a message',
                  style: GoogleFonts.cairo(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: provider.messages.length,
          itemBuilder: (context, index) {
            final message = provider.messages[index];
            return _buildMessageBubble(message);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMe = message.senderId == currentUser?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF00FF88).withOpacity(0.2),
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : 'U',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF00FF88),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF00FF88) : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: Border.all(
                  color: isMe ? Colors.transparent : Colors.grey[800]!,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.senderName,
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF00FF88),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (!isMe) const SizedBox(height: 4),
                  _buildMessageContent(message, isMe),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.timestamp),
                        style: GoogleFonts.cairo(
                          color: isMe ? Colors.black54 : Colors.grey[400],
                          fontSize: 11,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _getMessageStatusIcon(message.status),
                          size: 12,
                          color: Colors.black54,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF00FF88).withOpacity(0.2),
              child: Text(
                'A',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF00FF88),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(MessageModel message, bool isMe) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.message,
          style: GoogleFonts.cairo(
            color: isMe ? Colors.black : Colors.white,
            fontSize: 14,
          ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrls?.isNotEmpty == true)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.imageUrls!.first,
                  width: 200,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            if (message.message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.message,
                style: GoogleFonts.cairo(
                  color: isMe ? Colors.black : Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        );
      case MessageType.location:
        return Row(
          children: [
            const Icon(
              Icons.location_on,
              color: Color(0xFF00FF88),
              size: 16,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                message.message,
                style: GoogleFonts.cairo(
                  color: isMe ? Colors.black : Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      default:
        return Text(
          message.message,
          style: GoogleFonts.cairo(
            color: isMe ? Colors.black : Colors.white,
            fontSize: 14,
          ),
        );
    }
  }

  IconData _getMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      default:
        return Icons.access_time;
    }
  }

  String _formatMessageTime(DateTime dateTime) {
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

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Consumer<AdminIndividualChatProvider>(
        builder: (context, provider, child) {
          return Row(
            children: [
              IconButton(
                onPressed: () => _showAttachmentOptions(provider),
                icon: const Icon(
                  Icons.attach_file,
                  color: Color(0xFF00FF88),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: GoogleFonts.cairo(color: Colors.white),
                  maxLines: null,
                  onChanged: (text) {
                    if (text.isNotEmpty) {
                      provider.startTyping();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: GoogleFonts.cairo(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFF0A0A0A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF00FF88),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => _sendMessage(provider),
                  icon: const Icon(
                    Icons.send,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAttachmentOptions(AdminIndividualChatProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Send Attachment',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.image,
                  label: 'Image',
                  color: const Color(0xFF00FF88),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(provider);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.location_on,
                  label: 'Location',
                  color: const Color(0xFF4A90E2),
                  onTap: () {
                    Navigator.pop(context);
                    _shareLocation(provider);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'File',
                  color: const Color(0xFFFF6B35),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile(provider);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _pickImage(AdminIndividualChatProvider provider) {
    // Create a file input element
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files!.isNotEmpty) {
        final file = files[0];
        provider.sendImageMessage(file);
      }
    });
  }

  void _shareLocation(AdminIndividualChatProvider provider) {
    // For web, we'll use the Geolocation API
    html.window.navigator.geolocation!.getCurrentPosition().then((position) {
      final lat = position.coords!.latitude!;
      final lng = position.coords!.longitude!;
      provider.sendLocationMessage(lat.toDouble(), lng.toDouble(), 'Shared Location');
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _pickFile(AdminIndividualChatProvider provider) {
    // Create a file input element for documents
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.pdf,.doc,.docx,.txt';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files!.isNotEmpty) {
        final file = files[0];
        // You can implement file upload logic here
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File sharing coming soon!'),
            backgroundColor: Color(0xFF00FF88),
          ),
        );
      }
    });
  }

  void _sendMessage(AdminIndividualChatProvider provider) {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      provider.sendMessage(message);
      _messageController.clear();
      
      // Scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }
}