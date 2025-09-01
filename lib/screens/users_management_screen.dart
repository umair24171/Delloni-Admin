
import 'package:delloniweb/providers/user_provider.dart';
import 'package:delloniweb/resources/colors.dart';
import 'package:delloniweb/screens/dashboard_overview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _searchQuery = '';
  String _typeFilter = 'all';
  String _statusFilter = 'all';
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadAllUsers();
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
                  Icons.people_outline,
                  size: 28,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Users Management',
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
                              hintText: 'Search users by name, email, or company...',
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

                        // Type Filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _typeFilter,
                            decoration: const InputDecoration(
                              labelText: 'User Type',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Types')),
                              DropdownMenuItem(value: 'individual', child: Text('Individual')),
                              DropdownMenuItem(value: 'company', child: Text('Company')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _typeFilter = value!;
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
                              DropdownMenuItem(value: 'active', child: Text('Active')),
                              DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                              DropdownMenuItem(value: 'verified', child: Text('Verified')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _statusFilter = value!;
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
                        Consumer<UserProvider>(
                          builder: (context, provider, child) {
                            final filteredUsers = _getFilteredUsers(provider.allUsers);
                            return Text(
                              'Showing ${filteredUsers.length} users',
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
                                Provider.of<UserProvider>(context, listen: false)
                                    .loadAllUsers();
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

            // Users Table
            Expanded(
              child: Consumer<UserProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filteredUsers = _getFilteredUsers(provider.allUsers);
                  final paginatedUsers = _getPaginatedUsers(filteredUsers);

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No users found',
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
                                    const Expanded(flex: 2, child: Text('User', style: TextStyle(fontWeight: FontWeight.w600))),
                                    const Expanded(child: Text('Type', style: TextStyle(fontWeight: FontWeight.w600))),
                                    const Expanded(child: Text('Contact', style: TextStyle(fontWeight: FontWeight.w600))),
                                    const Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                                    const Expanded(child: Text('Joined', style: TextStyle(fontWeight: FontWeight.w600))),
                                    const SizedBox(width: 120, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),

                              // Table Body
                              Expanded(
                                child: ListView.separated(
                                  itemCount: paginatedUsers.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final user = paginatedUsers[index];
                                    return _buildUserRow(user, provider);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Pagination
                      if (filteredUsers.length > _itemsPerPage)
                        _buildPagination(filteredUsers.length),
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
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        final totalUsers = provider.allUsers.length;
        final companies = provider.allUsers.where((u) => u['type'] == 'company').length;
        final individuals = provider.allUsers.where((u) => u['type'] == 'individual').length;
        
        return Row(
          children: [
            _buildStatCard('Total Users', totalUsers.toString(), Icons.people, AppColors.primary),
            const SizedBox(width: 12),
            _buildStatCard('Companies', companies.toString(), Icons.business, AppColors.success),
            const SizedBox(width: 12),
            _buildStatCard('Individuals', individuals.toString(), Icons.person, AppColors.info),
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

    Widget _buildUserRow(Map<String, dynamic> user, UserProvider provider) {
  final isCompany = user['type'] == 'company';
  final userName = isCompany 
      ? (user['companyName'] ?? 'Unknown Company')
      : (user['name'] ?? user['email'] ?? 'Unknown User');
  final userEmail = user['email'] ?? '';
  final userPhone = user['phone'] ?? '';
  final isActive = user['isActive'] ?? true;
  final isEmailVerified = user['isEmailVerified'] ?? false;
  final isPhoneVerified = user['isPhoneVerified'] ?? false;
  
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

        // User Info
        Expanded(
          flex: 2,
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isCompany ? AppColors.primary : AppColors.success,
                backgroundImage: user['profileImage'] != null 
                    ? NetworkImage(user['profileImage'])
                    : null,
                child: user['profileImage'] == null
                    ? Text(
                        SafeStringUtils.getInitials(userName),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
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
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Type
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCompany 
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isCompany ? 'Company' : 'Individual',
              style: TextStyle(
                color: isCompany ? AppColors.primary : AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // Contact
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (userPhone.isNotEmpty)
                Text(
                  userPhone,
                  style: const TextStyle(fontSize: 12),
                ),
              Text(
                user['language'] ?? 'English',
                style: const TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        // Status
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getUserStatusColor(user).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'Active' : 'Blocked',
                  style: TextStyle(
                    color: _getUserStatusColor(user),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isEmailVerified)
                    const Icon(
                      Icons.email_outlined,
                      color: AppColors.success,
                      size: 14,
                    ),
                  if (isEmailVerified && isPhoneVerified)
                    const SizedBox(width: 4),
                  if (isPhoneVerified)
                    const Icon(
                      Icons.phone_outlined,
                      color: AppColors.success,
                      size: 14,
                    ),
                ],
              ),
            ],
          ),
        ),

        // Joined Date
        Expanded(
          child: Text(
            _formatDate(user['createdAt']),
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
                onPressed: () => _viewUser(user),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                tooltip: 'View Details',
              ),
              IconButton(
                onPressed: () => _contactUser(user),
                icon: const Icon(Icons.message_outlined, size: 18),
                tooltip: 'Contact',
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleUserAction(value, user, provider),
                itemBuilder: (context) => [
                  // Block/Unblock User
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Row(
                      children: [
                        Icon(
                          isActive ? Icons.block_outlined : Icons.check_circle_outline,
                          size: 18,
                          color: isActive ? Colors.red : AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isActive ? 'Block User' : 'Unblock User',
                          style: TextStyle(
                            color: isActive ? Colors.red : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Verify Email
                  if (!isEmailVerified)
                    PopupMenuItem(
                      value: 'verify_email',
                      child: Row(
                        children: [
                          Icon(
                            Icons.mark_email_read_outlined,
                            size: 18,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Verify Email',
                            style: TextStyle(color: AppColors.info),
                          ),
                        ],
                      ),
                    ),
                  
                  // Verify Phone
                  if (!isPhoneVerified)
                    PopupMenuItem(
                      value: 'verify_phone',
                      child: Row(
                        children: [
                          Icon(
                            Icons.phone_callback_outlined,
                            size: 18,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Verify Phone',
                            style: TextStyle(color: AppColors.info),
                          ),
                        ],
                      ),
                    ),
                  
                  // Reset Password
                  const PopupMenuItem(
                    value: 'reset_password',
                    child: Row(
                      children: [
                        Icon(Icons.lock_reset_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Reset Password'),
                      ],
                    ),
                  ),
                  
                  // View Products
                  // const PopupMenuItem(
                  //   value: 'view_products',
                  //   child: Row(
                  //     children: [
                  //       Icon(Icons.inventory_2_outlined, size: 18),
                  //       SizedBox(width: 8),
                  //       Text('View Products'),
                  //     ],
                  //   ),
                  // ),
                  
                  const PopupMenuDivider(),
                  
                  // Delete User
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Delete User',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
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
           
           
              // Pagination widget
              Widget _buildPagination(int totalItems) {
              final totalPages = (totalItems / _itemsPerPage).ceil();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                  ),
                  Text('Page $_currentPage of $totalPages'),
                  IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
                  ),
                ],
                ),
              );
              }

              // Filtering logic
              List<Map<String, dynamic>> _getFilteredUsers(List<Map<String, dynamic>> users) {
              return users.where((user) {
                final matchesSearch = _searchQuery.isEmpty ||
                  (user['name']?.toLowerCase().contains(_searchQuery) ?? false) ||
                  (user['email']?.toLowerCase().contains(_searchQuery) ?? false) ||
                  (user['companyName']?.toLowerCase().contains(_searchQuery) ?? false);

                final matchesType = _typeFilter == 'all' || user['type'] == _typeFilter;
                final matchesStatus = _statusFilter == 'all' ||
                  (_statusFilter == 'active' && user['isActive'] == true) ||
                  (_statusFilter == 'inactive' && user['isActive'] == false) ||
                  (_statusFilter == 'verified' && user['isEmailVerified'] == true);

                return matchesSearch && matchesType && matchesStatus;
              }).toList();
              }

              // Pagination logic
              List<Map<String, dynamic>> _getPaginatedUsers(List<Map<String, dynamic>> users) {
              final start = (_currentPage - 1) * _itemsPerPage;
              final end = (_currentPage * _itemsPerPage).clamp(0, users.length);
              return users.sublist(start, end);
              }

              // User status
              String _getUserStatus(Map<String, dynamic> user) {
              if (user['isActive'] == true) {
                return user['isEmailVerified'] == true ? 'Active & Verified' : 'Active';
              } else {
                return 'Inactive';
              }
              }

           

              // Date formatting
              String _formatDate(dynamic date) {
              if (date == null) return '-';
              try {
                final dt = date is String ? DateTime.parse(date) : date as DateTime;
                return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
              } catch (_) {
                return '-';
              }
              }

              // User actions
              void _viewUser(Map<String, dynamic> user) {
              // Implement navigation to user details
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                title: Text('User Details'),
                content: Text('Details for ${user['name'] ?? user['email']}'),
                actions: [
                  TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                  ),
                ],
                ),
              );
              }

              void _contactUser(Map<String, dynamic> user) {
              // Implement contact logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Contacting ${user['email']}')),
              );
              }

            void _handleUserAction(String action, Map<String, dynamic> user, UserProvider provider) async {
  final userId = user['id'];
  final userName = user['type'] == 'company' 
      ? (user['companyName'] ?? 'Unknown Company')
      : (user['name'] ?? user['email'] ?? 'Unknown User');
  final isActive = user['isActive'] ?? true;

  switch (action) {
    case 'toggle_status':
      final confirmed = await _showConfirmationDialog(
        title: isActive ? 'Block User' : 'Unblock User',
        content: isActive 
            ? 'Are you sure you want to block "$userName"? They will not be able to access their account.'
            : 'Are you sure you want to unblock "$userName"? They will regain access to their account.',
        confirmText: isActive ? 'Block' : 'Unblock',
        isDestructive: isActive,
      );
      
      if (confirmed) {
        try {
          await provider.updateUserStatus(userId, !isActive);
          _showSuccessSnackBar(
            isActive ? 'User blocked successfully' : 'User unblocked successfully'
          );
        } catch (e) {
          _showErrorSnackBar('Failed to update user status: $e');
        }
      }
      break;

    case 'verify_email':
      final confirmed = await _showConfirmationDialog(
        title: 'Verify Email',
        content: 'Are you sure you want to manually verify the email for "$userName"?',
        confirmText: 'Verify',
      );
      
      if (confirmed) {
        try {
          await provider.verifyUserEmail(userId);
          _showSuccessSnackBar('Email verified successfully');
        } catch (e) {
          _showErrorSnackBar('Failed to verify email: $e');
        }
      }
      break;

    case 'verify_phone':
      final confirmed = await _showConfirmationDialog(
        title: 'Verify Phone',
        content: 'Are you sure you want to manually verify the phone number for "$userName"?',
        confirmText: 'Verify',
      );
      
      if (confirmed) {
        try {
          await provider.verifyUserPhone(userId);
          _showSuccessSnackBar('Phone verified successfully');
        } catch (e) {
          _showErrorSnackBar('Failed to verify phone: $e');
        }
      }
      break;

    case 'reset_password':
      final confirmed = await _showConfirmationDialog(
        title: 'Reset Password',
        content: 'Are you sure you want to send a password reset email to "$userName"?',
        confirmText: 'Send Reset Email',
      );
      
      if (confirmed) {
        try {
          await provider.resetUserPassword(userId);
          _showSuccessSnackBar('Password reset email sent successfully');
        } catch (e) {
          _showErrorSnackBar('Failed to send reset email: $e');
        }
      }
      break;

    // case 'view_products':
    //   // Navigate to user's products
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder: (context) => UserProductsScreen(userId: userId, userName: userName),
    //     ),
    //   );
    //   break;

    case 'delete':
      final confirmed = await _showConfirmationDialog(
        title: 'Delete User',
        content: 'Are you sure you want to permanently delete "$userName"? This action cannot be undone and will also delete all their products and data.',
        confirmText: 'Delete',
        isDestructive: true,
      );
      
      if (confirmed) {
        // Double confirmation for deletion
        final doubleConfirmed = await _showConfirmationDialog(
          title: 'Final Confirmation',
          content: 'This will permanently delete the user and all associated data. Type "DELETE" to confirm.',
          confirmText: 'DELETE',
          isDestructive: true,
          requiresTextConfirmation: true,
        );
        
        if (doubleConfirmed) {
          try {
            await provider.deleteUser(userId);
            _showSuccessSnackBar('User deleted successfully');
          } catch (e) {
            _showErrorSnackBar('Failed to delete user: $e');
          }
        }
      }
      break;
  }
}
// Helper methods for dialogs and snackbars
Future<bool> _showConfirmationDialog({
  required String title,
  required String content,
  required String confirmText,
  bool isDestructive = false,
  bool requiresTextConfirmation = false,
}) async {
  if (requiresTextConfirmation) {
    return await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteConfirmationDialog(
        title: title,
        content: content,
        confirmText: confirmText,
      ),
    ) ?? false;
  }

  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: isDestructive ? Colors.red : AppColors.primary,
          ),
          child: Text(confirmText),
        ),
      ],
    ),
  ) ?? false;
}

void _showSuccessSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void _showErrorSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// Updated _getUserStatusColor method
Color _getUserStatusColor(Map<String, dynamic> user) {
  final isActive = user['isActive'] ?? true;
  final isEmailVerified = user['isEmailVerified'] ?? false;
  
  if (!isActive) {
    return Colors.red; // Blocked
  } else if (isEmailVerified) {
    return AppColors.success; // Active & Verified
  } else {
    return AppColors.warning; // Active but not verified
  }
}
}
// Custom dialog for delete confirmation
class _DeleteConfirmationDialog extends StatefulWidget {
  final String title;
  final String content;
  final String confirmText;

  const _DeleteConfirmationDialog({
    required this.title,
    required this.content,
    required this.confirmText,
  });

  @override
  State<_DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  final _controller = TextEditingController();
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _canConfirm = _controller.text.trim().toUpperCase() == widget.confirmText.toUpperCase();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.content),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Type "${widget.confirmText}" to confirm',
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _canConfirm ? () => Navigator.pop(context, true) : null,
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}
            