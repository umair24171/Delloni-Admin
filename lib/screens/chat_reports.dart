import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delloniweb/controllers/admin_data_provider.dart';
import 'package:delloniweb/providers/reports_provider.dart';
import 'package:delloniweb/resources/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
class ReportsManagementScreen extends StatefulWidget {
  const ReportsManagementScreen({Key? key}) : super(key: key);

  @override
  State<ReportsManagementScreen> createState() => _ReportsManagementScreenState();
}

class _ReportsManagementScreenState extends State<ReportsManagementScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedReason;
  String? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';

  // NEW: Tab management for different report types
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['All Reports', 'Chat Reports', 'Account Reports'];

  @override
  void initState() {
    super.initState();
   SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
    _loadReports();
   });
  }

  void _loadReports() {
    final provider = Provider.of<ReportsProvider>(context, listen: false);
    provider.loadAllReports(); // This now loads both types
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports Management'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
            tooltip: 'Refresh Reports',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // NEW: Tab Bar for Report Types
          _buildTabBar(),
          
          // Filters Section
          _buildFiltersSection(),
          
          // Reports List
          Expanded(
            child: _buildReportsContent(),
          ),
        ],
      ),
    );
  }

  // NEW: Tab Bar Widget
  Widget _buildTabBar() {
    return Container(
      color: AppColors.white,
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedTabIndex == index;
          
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                  // Clear filters when switching tabs
                  _selectedStatus = null;
                  _selectedReason = null;
                  _selectedType = null;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.primary : AppColors.textMedium,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.white,
      child: Column(
        children: [
          // Search Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search reports by reason, details, or user ID...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  _showFilterDialog();
                },
                icon: const Icon(Icons.filter_list),
                label: const Text('Filters'),
              ),
            ],
          ),
          
          // Active Filters
          if (_selectedStatus != null || _selectedReason != null || _selectedType != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedStatus != null)
                    _buildFilterChip('Status: $_selectedStatus', () {
                      setState(() {
                        _selectedStatus = null;
                      });
                    }),
                  if (_selectedReason != null)
                    _buildFilterChip('Reason: $_selectedReason', () {
                      setState(() {
                        _selectedReason = null;
                      });
                    }),
                  if (_selectedType != null)
                    _buildFilterChip('Type: $_selectedType', () {
                      setState(() {
                        _selectedType = null;
                      });
                    }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Chip(
      label: Text(label),
      onDeleted: onDeleted,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      deleteIconColor: AppColors.primary,
    );
  }

  Widget _buildReportsContent() {
    return Consumer<ReportsProvider>(
      builder: (context, provider, child) {
        // if (provider.isLoading) {
        //   return const Center(
        //     child: CircularProgressIndicator(),
        //   );
        // }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading reports',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  style: TextStyle(
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadReports,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        // NEW: Filter reports based on selected tab
        List<Map<String, dynamic>> reportsToShow = [];
        
        switch (_selectedTabIndex) {
          case 0: // All Reports
            reportsToShow = [...provider.allChatReports, ...provider.allAccountReports];
            break;
          case 1: // Chat Reports
            reportsToShow = provider.allChatReports;
            break;
          case 2: // Account Reports
            reportsToShow = provider.allAccountReports;
            break;
        }

        // Apply additional filters
        List<Map<String, dynamic>> filteredReports = provider.filterReports(
          reports: reportsToShow,
          status: _selectedStatus,
          reason: _selectedReason,
          type: _selectedType,
          startDate: _startDate,
          endDate: _endDate,
        );

        if (_searchQuery.isNotEmpty) {
          filteredReports = filteredReports.where((report) {
            final reason = (report['reportReason'] as String? ?? report['reason'] as String? ?? '').toLowerCase();
            final details = (report['additionalComments'] as String? ?? report['details'] as String? ?? '').toLowerCase();
            final reportedUserName = (report['reportedUserName'] as String? ?? '').toLowerCase();
            final query = _searchQuery.toLowerCase();
            return reason.contains(query) || details.contains(query) || reportedUserName.contains(query);
          }).toList();
        }

        // Sort by creation date
        filteredReports.sort((a, b) {
          final aDate = a['createdAt'] as Timestamp?;
          final bDate = b['createdAt'] as Timestamp?;
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        });

        if (filteredReports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.report_off,
                  size: 64,
                  color: AppColors.textMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'No reports found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'There are no reports matching your criteria.',
                  style: TextStyle(
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          );
        }

        return _buildReportsTable(filteredReports);
      },
    );
  }

  Widget _buildReportsTable(List<Map<String, dynamic>> reports) {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Card(
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.report, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${_tabs[_selectedTabIndex]} (${reports.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            
            // Table Content
            Expanded(
              child: ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return _buildReportItem(report);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildReportItem(Map<String, dynamic> report) {
  // NEW: Determine if this is a chat report or account report
  final isAccountReport = report['reportType'] == 'user';
  final reportSource = isAccountReport ? 'ACCOUNT' : 'CHAT';
  
  final status = report['status'] as String? ?? 'pending';
  final reason = (report['reportReason'] as String? ?? report['reason'] as String? ?? 'Unknown');
  final details = (report['additionalComments'] as String? ?? report['details'] as String? ?? '');
  final createdAt = report['createdAt'] as Timestamp?;
  final reportedUserId = report['reportedUserId'] as String? ?? '';
  final reportedBy = (report['reporterId'] as String? ?? report['reportedBy'] as String? ?? '');
  final reportedUserName = report['reportedUserName'] as String? ?? 'Unknown User';

  Color statusColor;
  switch (status.toLowerCase()) {
    case 'resolved':
      statusColor = AppColors.success;
      break;
    case 'rejected':
      statusColor = AppColors.error;
      break;
    case 'under_review':
      statusColor = AppColors.warning;
      break;
    default:
      statusColor = AppColors.info;
  }

  Color sourceColor = isAccountReport ? Colors.orange : Colors.blue;

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: ExpansionTile(
      title: Row(
        children: [
          // NEW: Report Source Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: sourceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: sourceColor),
            ),
            child: Text(
              reportSource,
              style: TextStyle(
                color: sourceColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ENHANCED: Show reported user info with verification status
          Row(
            children: [
              // User Avatar
              CircleAvatar(
                radius: 12,
                backgroundImage: report['reportedUserProfileImage'] != null
                    ? NetworkImage(report['reportedUserProfileImage'])
                    : null,
                child: report['reportedUserProfileImage'] == null
                    ? Icon(Icons.person, size: 16, color: AppColors.textMedium)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reported User: $reportedUserName',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Verification Badge
              if (report['reportedUserVerified'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 12, color: AppColors.success),
                      const SizedBox(width: 2),
                      Text(
                        'VERIFIED',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              // Online Status
              if (report['reportedUserOnline'] == true)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          
          // User Type and Rating
          if (report['reportedUserType'] != null || report['reportedUserRating'] != null)
            Row(
              children: [
                if (report['reportedUserType'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      (report['reportedUserType'] as String).toUpperCase(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (report['reportedUserRating'] != null && report['reportedUserRating'] > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Row(
                      children: [
                        Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '${report['reportedUserRating'].toStringAsFixed(1)} (${report['reportedUserReviewCount'] ?? 0})',
                          style: TextStyle(
                            color: AppColors.textMedium,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          
          const SizedBox(height: 4),
          if (details.isNotEmpty)
            Text(
              details,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textMedium,
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'Reported: ${createdAt != null ? DateFormat('MMM dd, yyyy - HH:mm').format(createdAt.toDate()) : 'Unknown'}',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
            ),
          ),
        ],
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Report Details
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Report ID', report['reportId'] ?? report['id'] ?? 'Unknown'),
                        _buildDetailRow('Report Type', reportSource),
                        
                        // NEW: Show different fields based on report type
                        if (isAccountReport) ...[
                          _buildDetailRow('Reported User ID', reportedUserId),
                          _buildDetailRow('Reported User Name', reportedUserName),
                          _buildDetailRow('Reporter ID', reportedBy),
                          _buildDetailRow('Reporter Name', report['reporterName'] ?? 'Unknown'),
                          _buildDetailRow('Reason', report['reportReasonTitle'] ?? reason),
                        ] else ...[
                          _buildDetailRow('Chat ID', report['chatId'] ?? 'Unknown'),
                          _buildDetailRow('Product ID', report['productId'] ?? 'Unknown'),
                          _buildDetailRow('Product Owner ID', report['productOwnerId'] ?? 'Unknown'),
                          _buildDetailRow('Reported User', reportedUserId),
                          _buildDetailRow('Reported By', reportedBy),
                          _buildDetailRow('Reason', reason),
                        ],
                        
                        // ENHANCED: User Details Section
                        if (report['reportedUserEmail'] != null || report['reportedUserPhone'] != null)
                          const Divider(),
                        if (report['reportedUserEmail'] != null || report['reportedUserPhone'] != null)
                          Text(
                            'Reported User Details:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                              fontSize: 14,
                            ),
                          ),
                        if (report['reportedUserEmail'] != null)
                          _buildDetailRow('Email', report['reportedUserEmail']),
                        if (report['reportedUserPhone'] != null)
                          _buildDetailRow('Phone', report['reportedUserPhone']),
                        if (report['reportedUserCompanyName'] != null)
                          _buildDetailRow('Company', report['reportedUserCompanyName']),
                        if (report['reportedUserAddress'] != null)
                          _buildDetailRow('Address', report['reportedUserAddress']),
                        if (report['reportedUserTotalAds'] != null)
                          _buildDetailRow('Total Ads', report['reportedUserTotalAds'].toString()),
                        if (report['reportedUserMemberSince'] != null)
                          _buildDetailRow('Member Since', DateFormat('MMM dd, yyyy').format(report['reportedUserMemberSince'])),
                        if (report['reportedUserLastSeen'] != null)
                          _buildDetailRow('Last Seen', DateFormat('MMM dd, yyyy HH:mm').format(report['reportedUserLastSeen'])),
                        
                        if (details.isNotEmpty)
                          _buildDetailRow('Details', details),
                        if (report['adminNotes'] != null)
                          _buildDetailRow('Admin Notes', report['adminNotes']),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Actions
                  Column(
                    children: [
                      // NEW: Show different actions based on report type
                      // if (!isAccountReport)
                      //   _buildActionButton(
                      //     'View Chat',
                      //     Icons.chat,
                      //     AppColors.info,
                      //     () => _viewChat(report['chatId']),
                      //   ),
                      // if (!isAccountReport)
                      //   const SizedBox(height: 8),
                      
                      // _buildActionButton(
                      //   'View User',
                      //   Icons.person,
                      //   AppColors.primary,
                      //   () => _viewUser(reportedUserId),
                      // ),
                      // const SizedBox(height: 8),
                      // _buildActionButton(
                      //   'User Actions',
                      //   Icons.admin_panel_settings,
                      //   Colors.purple,
                      //   () => _showUserActionsDialog(report),
                      // ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        'Update Status',
                        Icons.edit,
                        AppColors.warning,
                        () => _showUpdateStatusDialog(report),
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        'Delete',
                        Icons.delete,
                        AppColors.error,
                        () => _deleteReport(report),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
void _showUserActionsDialog(Map<String, dynamic> report) {
  final reportedUserId = report['reportedUserId'] as String?;
  final reportedUserName = report['reportedUserName'] as String? ?? 'Unknown User';
  
  if (reportedUserId == null || reportedUserId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cannot perform actions: User ID not found'),
        backgroundColor: AppColors.error,
      ),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Actions for $reportedUserName'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User Info Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: report['reportedUserProfileImage'] != null
                          ? NetworkImage(report['reportedUserProfileImage'])
                          : null,
                      child: report['reportedUserProfileImage'] == null
                          ? Icon(Icons.person, color: AppColors.textMedium)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reportedUserName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (report['reportedUserEmail'] != null)
                            Text(
                              report['reportedUserEmail'],
                              style: TextStyle(
                                color: AppColors.textMedium,
                                fontSize: 12,
                              ),
                            ),
                          Row(
                            children: [
                              if (report['reportedUserVerified'] == true)
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    'VERIFIED',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              if (report['reportedUserType'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    (report['reportedUserType'] as String).toUpperCase(),
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Action Buttons
              _buildUserActionButton(
                'Send Warning',
                Icons.warning_amber,
                Colors.orange,
                () => _takeUserAction(reportedUserId, 'warning', reportedUserName),
              ),
              const SizedBox(height: 8),
              _buildUserActionButton(
                'Suspend Account',
                Icons.block,
                AppColors.error,
                () => _takeUserAction(reportedUserId, 'suspend', reportedUserName),
              ),
              const SizedBox(height: 8),
              _buildUserActionButton(
                'Ban Account',
                Icons.gavel,
                Colors.red[900]!,
                () => _takeUserAction(reportedUserId, 'ban', reportedUserName),
              ),
              const SizedBox(height: 8),
              _buildUserActionButton(
                'Delete Content',
                Icons.delete_sweep,
                Colors.purple,
                () => _takeUserAction(reportedUserId, 'delete_content', reportedUserName),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
Widget _buildUserActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
  return SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    ),
  );
}

void _takeUserAction(String userId, String action, String userName) {
  Navigator.of(context).pop(); // Close actions dialog
  
  final reasonController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('${action.replaceAll('_', ' ').toUpperCase()} - $userName'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Are you sure you want to $action this user?'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'Provide a reason for this action...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final provider = Provider.of<ReportsProvider>(context, listen: false);
              provider.takeActionOnReportedUser(
                userId,
                action,
                reason: reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : null,
              );
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Action "$action" applied to $userName'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('Apply ${action.replaceAll('_', ' ').toUpperCase()}'),
          ),
        ],
      );
    },
  );
}


  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 120,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Reports'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Statuses')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'under_review', child: Text('Under Review')),
                    DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedReason,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Reasons')),
                    // NEW: Include account report reasons
                    DropdownMenuItem(value: 'fake_profile', child: Text('Fake Profile')),
                    DropdownMenuItem(value: 'inappropriate_content', child: Text('Inappropriate Content')),
                    DropdownMenuItem(value: 'spam', child: Text('Spam')),
                    DropdownMenuItem(value: 'scam', child: Text('Scam/Fraud')),
                    DropdownMenuItem(value: 'harassment', child: Text('Harassment')),
                    DropdownMenuItem(value: 'intellectual_property', child: Text('Intellectual Property')),
                    DropdownMenuItem(value: 'minor_safety', child: Text('Minor Safety')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Types')),
                    DropdownMenuItem(value: 'user', child: Text('Account Report')),
                    DropdownMenuItem(value: 'message', child: Text('Chat Report')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedStatus = null;
                  _selectedReason = null;
                  _selectedType = null;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Clear All'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {});
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateStatusDialog(Map<String, dynamic> report) {
    final notesController = TextEditingController();
    String selectedStatus = report['status'] ?? 'pending';
    final isAccountReport = report['reportType'] == 'user';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update ${isAccountReport ? 'Account' : 'Chat'} Report Status'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'under_review', child: Text('Under Review')),
                    DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (value) {
                    selectedStatus = value!;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Admin Notes',
                    hintText: 'Add any notes about this report...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final provider = Provider.of<ReportsProvider>(context, listen: false);
                provider.updateReportStatus(
                  report,
                  selectedStatus,
                  adminNotes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _viewChat(String? chatId) {
    if (chatId == null) return;
    // Implement chat viewing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View chat: $chatId'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _viewUser(String userId) {
    if (userId.isEmpty) return;
    // Implement user viewing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View user: $userId'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _deleteReport(Map<String, dynamic> report) {
    final isAccountReport = report['reportType'] == 'user';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete ${isAccountReport ? 'Account' : 'Chat'} Report'),
          content: const Text('Are you sure you want to delete this report? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final provider = Provider.of<ReportsProvider>(context, listen: false);
                provider.deleteReport(report);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}