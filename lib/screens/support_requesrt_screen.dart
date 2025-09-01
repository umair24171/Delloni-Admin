import 'package:delloniweb/controllers/admin_data_provider.dart';
import 'package:delloniweb/providers/support_provider.dart';
import 'package:delloniweb/resources/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
class SupportRequestsScreen extends StatefulWidget {
  const SupportRequestsScreen({Key? key}) : super(key: key);

  @override
  State<SupportRequestsScreen> createState() => _SupportRequestsScreenState();
}

class _SupportRequestsScreenState extends State<SupportRequestsScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _categoryFilter = 'all';
  String _priorityFilter = 'all';
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SupportProvider>(context, listen: false).loadSupportRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.support_agent_outlined,
                  size: 28,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Support Requests',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                _buildStatsCards(),
              ],
            ),
            const SizedBox(height: 24),

            // Filters and Search
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Search
                        Expanded(
                          flex: 2,
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search by subject, email, or content...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.toLowerCase();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Status Filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _statusFilter,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Status')),
                              DropdownMenuItem(value: 'pending', child: Text('Pending')),
                              DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                              DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                              DropdownMenuItem(value: 'closed', child: Text('Closed')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _statusFilter = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Category Filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _categoryFilter,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Categories')),
                              DropdownMenuItem(value: 'general', child: Text('General')),
                              DropdownMenuItem(value: 'technical', child: Text('Technical')),
                              DropdownMenuItem(value: 'billing', child: Text('Billing')),
                              DropdownMenuItem(value: 'account', child: Text('Account')),
                              DropdownMenuItem(value: 'bug', child: Text('Bug Report')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _categoryFilter = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Priority Filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _priorityFilter,
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Priorities')),
                              DropdownMenuItem(value: 'low', child: Text('Low')),
                              DropdownMenuItem(value: 'medium', child: Text('Medium')),
                              DropdownMenuItem(value: 'high', child: Text('High')),
                              DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _priorityFilter = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Consumer<SupportProvider>(
                          builder: (context, provider, child) {
                            final filteredRequests = _getFilteredRequests(provider.supportRequests);
                            return Text(
                              'Showing ${filteredRequests.length} requests',
                              style: const TextStyle(
                                color: AppColors.textMedium,
                                fontSize: 14,
                              ),
                            );
                          },
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                Provider.of<SupportProvider>(context, listen: false)
                                    .loadSupportRequests();
                              },
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Refresh',
                            ),
                            IconButton(
                              onPressed: () {
                                // Export functionality
                              },
                              icon: const Icon(Icons.download),
                              tooltip: 'Export',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Support Requests Table
            Expanded(
              child: Consumer<SupportProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filteredRequests = _getFilteredRequests(provider.supportRequests);
                  final paginatedRequests = _getPaginatedRequests(filteredRequests);

                  if (filteredRequests.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.support_agent_outlined,
                            size: 64,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No support requests found',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textMedium,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try adjusting your search or filter criteria',
                            style: TextStyle(color: AppColors.textLight),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: Card(
                          child: Column(
                            children: [
                              // Table Header
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: false,
                                      onChanged: (value) {
                                        // Select all functionality
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(flex: 2, child: Text('Request', style: TextStyle(fontWeight: FontWeight.w600))),
                                    const Expanded(child: Text('Category', style: TextStyle(fontWeight: FontWeight.w600))),
                                    const Expanded(child: Text('Priority', style: TextStyle(fontWeight: FontWeight.w600))),
                                    const Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                                    const Expanded(child: Text('Created', style: TextStyle(fontWeight: FontWeight.w600))),
                                    const SizedBox(width: 120, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),

                              // Table Body
                              Expanded(
                                child: ListView.separated(
                                  itemCount: paginatedRequests.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final request = paginatedRequests[index];
                                    return _buildRequestRow(request, provider);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Pagination
                      if (filteredRequests.length > _itemsPerPage)
                        _buildPagination(filteredRequests.length),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
        return Consumer<SupportProvider>(
      builder: (context, provider, child) {
        final totalRequests = provider.supportRequests.length;
        final pendingRequests = provider.supportRequests.where((r) => r['status'] == 'pending').length;
        final resolvedRequests = provider.supportRequests.where((r) => r['status'] == 'resolved').length;
        
        return Row(
          children: [
            _buildStatCard('Total', totalRequests.toString(), Icons.support_agent, AppColors.primary),
            const SizedBox(width: 12),
            _buildStatCard('Pending', pendingRequests.toString(), Icons.pending, AppColors.warning),
            const SizedBox(width: 12),
            _buildStatCard('Resolved', resolvedRequests.toString(), Icons.check_circle, AppColors.success),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestRow(Map<String, dynamic> request, SupportProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Checkbox(
            value: false,
            onChanged: (value) {
              // Select item functionality
            },
          ),
          const SizedBox(width: 12),

          // Request Info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request['subject'] ?? 'No Subject',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'From: ${request['name'] ?? 'Unknown'} (${request['email'] ?? 'Unknown'})',
                  style: const TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  request['message'] ?? 'No message',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Category
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCategoryColor(request['category']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                (request['category'] ?? 'general').toUpperCase(),
                style: TextStyle(
                  color: _getCategoryColor(request['category']),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Priority
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPriorityColor(request['priority']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                (request['priority'] ?? 'medium').toUpperCase(),
                style: TextStyle(
                  color: _getPriorityColor(request['priority']),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Status
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(request['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                (request['status'] ?? 'pending').toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(request['status']),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Created Date
          Expanded(
            child: Text(
              _formatDate(request['createdAt']),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMedium,
              ),
            ),
          ),

          // Actions
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _viewRequest(request),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  tooltip: 'View Details',
                ),
                IconButton(
                  onPressed: () => _respondToRequest(request, provider),
                  icon: const Icon(Icons.reply_outlined, size: 18),
                  tooltip: 'Respond',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleRequestAction(value, request, provider),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'mark_progress',
                      child: Row(
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 18,
                            color: request['status'] == 'in_progress' ? AppColors.textLight : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mark In Progress',
                            style: TextStyle(
                              color: request['status'] == 'in_progress' ? AppColors.textLight : null,
                            ),
                          ),
                        ],
                      ),
                      enabled: request['status'] != 'in_progress',
                    ),
                    PopupMenuItem(
                      value: 'mark_resolved',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: request['status'] == 'resolved' ? AppColors.textLight : AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mark Resolved',
                            style: TextStyle(
                              color: request['status'] == 'resolved' ? AppColors.textLight : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      enabled: request['status'] != 'resolved',
                    ),
                    const PopupMenuItem(
                      value: 'escalate',
                      child: Row(
                        children: [
                          Icon(Icons.trending_up_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Escalate'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'close',
                      child: Row(
                        children: [
                          Icon(Icons.close_outlined, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Close', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalItems) {
    final totalPages = (totalItems / _itemsPerPage).ceil();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing ${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage * _itemsPerPage).clamp(0, totalItems)} of $totalItems',
              style: const TextStyle(color: AppColors.textMedium),
            ),
            Row(
              children: [
                DropdownButton<int>(
                  value: _itemsPerPage,
                  items: [5, 10, 25, 50].map((items) {
                    return DropdownMenuItem(
                      value: items,
                      child: Text('$items per page'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _itemsPerPage = value!;
                      _currentPage = 1;
                    });
                  },
                  underline: const SizedBox(),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _currentPage > 1 ? () {
                    setState(() {
                      _currentPage--;
                    });
                  } : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('$_currentPage of $totalPages'),
                IconButton(
                  onPressed: _currentPage < totalPages ? () {
                    setState(() {
                      _currentPage++;
                    });
                  } : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredRequests(List<Map<String, dynamic>> requests) {
    return requests.where((request) {
      final subject = (request['subject'] ?? '').toLowerCase();
      final email = (request['email'] ?? '').toLowerCase();
      final message = (request['message'] ?? '').toLowerCase();
      
      final matchesSearch = _searchQuery.isEmpty ||
          subject.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          message.contains(_searchQuery);

      final matchesStatus = _statusFilter == 'all' ||
          request['status'] == _statusFilter;

      final matchesCategory = _categoryFilter == 'all' ||
          request['category'] == _categoryFilter;

      final matchesPriority = _priorityFilter == 'all' ||
          request['priority'] == _priorityFilter;

      return matchesSearch && matchesStatus && matchesCategory && matchesPriority;
    }).toList();
  }

  List<Map<String, dynamic>> _getPaginatedRequests(List<Map<String, dynamic>> requests) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, requests.length);
    return requests.sublist(startIndex, endIndex);
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.info;
      case 'resolved':
        return AppColors.success;
      case 'closed':
        return AppColors.textMedium;
      default:
        return AppColors.textMedium;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'bug':
        return AppColors.error;
      case 'technical':
        return AppColors.info;
      case 'billing':
        return AppColors.warning;
      case 'account':
        return AppColors.primary;
      default:
        return AppColors.textMedium;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'urgent':
        return AppColors.error;
      case 'high':
        return Colors.deepOrange;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.textMedium;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else {
        date = timestamp.toDate();
      }
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _viewRequest(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Support Request Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Request Info
              _buildDetailRow('Subject', request['subject'] ?? 'No Subject'),
              _buildDetailRow('From', '${request['name'] ?? 'Unknown'} (${request['email'] ?? 'Unknown'})'),
              _buildDetailRow('Phone', request['phoneNumber'] ?? 'Not provided'),
              _buildDetailRow('Category', request['category'] ?? 'General'),
              _buildDetailRow('Priority', request['priority'] ?? 'Medium'),
              _buildDetailRow('Status', request['status'] ?? 'Pending'),
              _buildDetailRow('Created', _formatDate(request['createdAt'])),
              
              const SizedBox(height: 16),
              const Text(
                'Message:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  request['message'] ?? 'No message provided',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              
              if (request['adminResponse'] != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Admin Response:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    request['adminResponse'],
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _respondToRequest(request, Provider.of<SupportProvider>(context, listen: false));
                    },
                    icon: const Icon(Icons.reply, size: 18),
                    label: const Text('Respond'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  void _respondToRequest(Map<String, dynamic> request, SupportProvider provider) {
    final responseController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Respond to Request',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Text(
                'Subject: ${request['subject'] ?? 'No Subject'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                'From: ${request['email'] ?? 'Unknown'}',
                style: const TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 12,
                ),
              ),
              
              const SizedBox(height: 16),
              TextField(
                controller: responseController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Your Response',
                  hintText: 'Type your response here...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (responseController.text.trim().isNotEmpty) {
                        provider.updateSupportRequestStatus(
                          request['id'],
                          'resolved',
                          response: responseController.text.trim(),
                        );
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Response sent successfully'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    child: const Text('Send Response'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRequestAction(String action, Map<String, dynamic> request, SupportProvider provider) {
    switch (action) {
      case 'mark_progress':
        provider.updateSupportRequestStatus(request['id'], 'in_progress');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request marked as in progress'),
            backgroundColor: AppColors.info,
          ),
        );
        break;
      case 'mark_resolved':
        provider.updateSupportRequestStatus(request['id'], 'resolved');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request marked as resolved'),
            backgroundColor: AppColors.success,
          ),
        );
        break;
      case 'escalate':
        _escalateRequest(request);
        break;
      case 'close':
        _closeRequest(request, provider);
        break;
    }
  }

  void _escalateRequest(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escalate Request'),
        content: const Text('This request will be escalated to senior support team.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Request escalated successfully'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Escalate'),
          ),
        ],
      ),
    );
  }

  void _closeRequest(Map<String, dynamic> request, SupportProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Request'),
        content: const Text('Are you sure you want to close this support request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.updateSupportRequestStatus(request['id'], 'closed');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Request closed successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}