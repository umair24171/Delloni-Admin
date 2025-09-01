import 'package:delloniweb/controllers/individual_chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminChatQuickActions extends StatelessWidget {
  final AdminIndividualChatProvider chatProvider;

  const AdminChatQuickActions({
    Key? key,
    required this.chatProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickActionChip(
                'Welcome',
                const Color(0xFF00FF88),
                () => chatProvider.sendPredefinedResponse('welcome'),
              ),
              _buildQuickActionChip(
                'Support',
                const Color(0xFF4A90E2),
                () => chatProvider.sendPredefinedResponse('support'),
              ),
              _buildQuickActionChip(
                'Thank You',
                const Color(0xFFFFB800),
                () => chatProvider.sendPredefinedResponse('thank_you'),
              ),
              _buildQuickActionChip(
                'Resolved',
                const Color(0xFF50C878),
                () => chatProvider.sendPredefinedResponse('resolved'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Quick Replies',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _buildQuickReplyTile(
                'How can I help you today?',
                Icons.help_outline,
                () => chatProvider.sendQuickReply('How can I help you today?'),
              ),
              _buildQuickReplyTile(
                'Please provide more details about your issue.',
                Icons.info_outline,
                () => chatProvider.sendQuickReply('Please provide more details about your issue.'),
              ),
              _buildQuickReplyTile(
                'I\'ll look into this and get back to you shortly.',
                Icons.schedule,
                () => chatProvider.sendQuickReply('I\'ll look into this and get back to you shortly.'),
              ),
              _buildQuickReplyTile(
                'Is there anything else I can assist you with?',
                Icons.question_answer,
                () => chatProvider.sendQuickReply('Is there anything else I can assist you with?'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReplyTile(String message, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: const Color(0xFF00FF88), size: 20),
        title: Text(
          message,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          Icons.send,
          color: Colors.grey[400],
          size: 16,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: const Color(0xFF0A0A0A),
      ),
    );
  }
}