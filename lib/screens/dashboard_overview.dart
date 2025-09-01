import 'dart:async';
import 'dart:math' as math;

import 'package:delloniweb/controllers/admin_data_provider.dart';
import 'package:delloniweb/providers/admin_data_provider.dart';
import 'package:delloniweb/providers/user_provider.dart';
import 'package:delloniweb/resources/colors.dart';
import 'package:delloniweb/screens/dashboard_layout.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:delloniweb/controllers/admin_data_provider.dart';
import 'package:delloniweb/resources/colors.dart';
import 'package:delloniweb/screens/dashboard_layout.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({Key? key}) : super(key: key);

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> 
    with AutomaticKeepAliveClientMixin {
  
  late Timer _refreshTimer;
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
    _setupAutoRefresh();
    _loadCurrentUser();
  }

  void _initializeDashboard() {
    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final provider = Provider.of<DashboardDataProvider>(context, listen: false);
          provider.loadDashboardData();
          // provider.loadAnalyticsData();
          _isInitialized = true;
        }
      });
    }
  }

  void _loadCurrentUser() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.loadCurrentUser();
  }

  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        Provider.of<DashboardDataProvider>(context, listen: false)
            .refreshDashboardData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: ArabicTheme.backgroundDark,
      body: Consumer<DashboardDataProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !_isInitialized) {
            return const _LoadingShimmer();
          }

          if (provider.error != null) {
            return _buildErrorState(provider);
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshDashboardData(),
            color: ArabicTheme.lightGreen,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Welcome Section
                      _WelcomeSection(provider: provider),
                      const SizedBox(height: 24),

                      // Stats Cards
                      _StatsCardsSection(provider: provider),
                      const SizedBox(height: 24),

                      // Analytics Dashboard
                      _AnalyticsSection(provider: provider),
                      const SizedBox(height: 24),

                      // Geographic Insights (without map)
                      _GeographicSection(provider: provider),
                      const SizedBox(height: 24),

                      // Content Overview
                      _ContentSection(provider: provider),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(DashboardDataProvider provider) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ArabicTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ArabicTheme.error.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: ArabicTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading dashboard',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ArabicTheme.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: ArabicTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => provider.refreshDashboardData(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArabicTheme.error,
                  foregroundColor: ArabicTheme.textLight,
                ),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extracted Welcome Section Widget
class _WelcomeSection extends StatelessWidget {
  final DashboardDataProvider provider;

  const _WelcomeSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ArabicTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return Row(
              children: [
                Expanded(child: _buildWelcomeContent()),
                const SizedBox(width: 24),
                SizedBox(
                  width: 200,
                  child: _buildWelcomeStats(),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                _buildWelcomeContent(),
                const SizedBox(height: 16),
                _buildWelcomeStats(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildWelcomeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Welcome back, Admin!',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: ArabicTheme.backgroundDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your marketplace is thriving with ${provider.totalUsers} users and ${provider.totalProducts} active listings.',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: ArabicTheme.backgroundDark,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => provider.refreshDashboardData(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Refresh', style: TextStyle(color: ArabicTheme.backgroundDark),),
          style: ElevatedButton.styleFrom(
            backgroundColor: ArabicTheme.textLight.withOpacity(0.2),
            foregroundColor: ArabicTheme.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ArabicTheme.textLight.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArabicTheme.textLight.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuickStat(
            label: 'Today\'s New Users',
            value: provider.todayNewUsers.toString(),
            icon: Icons.person_add_rounded,
            color: ArabicTheme.lightGold,
          ),
          const SizedBox(height: 12),
          _QuickStat(
            label: 'New Listings',
            value: provider.todayNewProducts.toString(),
            icon: Icons.add_business_rounded,
            color: ArabicTheme.lightGold,
          ),
          const SizedBox(height: 12),
          _QuickStat(
            label: 'Active Chats',
            value: provider.activeChats.toString(),
            icon: Icons.chat_bubble_rounded,
            color: ArabicTheme.lightGold,
          ),
        ],
      ),
    );
  }
}

// Stats Cards Section
class _StatsCardsSection extends StatelessWidget {
  final DashboardDataProvider provider;

  const _StatsCardsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 1;
        if (constraints.maxWidth > 600) columns = 2;
        if (constraints.maxWidth > 900) columns = 3;
        if (constraints.maxWidth > 1200) columns = 4;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          childAspectRatio: 1.4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _StatCard(
              title: 'Total Users',
              value: provider.totalUsers,
              icon: Icons.people_rounded,
              color: ArabicTheme.info,
              change: provider.userGrowthPercentage,
              subtitle: '${provider.newUsersThisWeek} this week',
            ),
            _StatCard(
              title: 'Active Listings',
              value: provider.totalProducts,
              icon: Icons.inventory_2_rounded,
              color: ArabicTheme.lightGreen,
              change: provider.listingGrowthPercentage,
              subtitle: '${provider.newListingsThisWeek} this week',
            ),
            _StatCard(
              title: 'Total Revenue',
              value: provider.totalRevenue,
              icon: Icons.attach_money_rounded,
              color: ArabicTheme.gold,
              change: provider.revenueGrowthPercentage,
              subtitle: 'PKR ${NumberFormat.compact().format(provider.monthlyRevenue)}/month',
              isRevenue: true,
            ),
            _StatCard(
              title: 'Active Chats',
              value: provider.activeChats,
              icon: Icons.chat_rounded,
              color: ArabicTheme.warning,
              change: provider.chatGrowthPercentage,
              subtitle: '${provider.averageResponseTime}m avg response',
            ),
          ],
        );
      },
    );
  }
}

// Analytics Section
class _AnalyticsSection extends StatelessWidget {
  final DashboardDataProvider provider;

  const _AnalyticsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Analytics Overview',
          subtitle: 'Key insights from your marketplace',
        ),
        const SizedBox(height: 16),
        
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _TopSearchesCard(provider: provider)),
                  const SizedBox(width: 16),
                  Expanded(child: _CategoryTrendsCard(provider: provider)),
                ],
              );
            } else {
              return Column(
                children: [
                  _TopSearchesCard(provider: provider),
                  const SizedBox(height: 16),
                  _CategoryTrendsCard(provider: provider),
                ],
              );
            }
          },
        ),
      ],
    );
  }
}

// Geographic Section (without map)
class _GeographicSection extends StatelessWidget {
  final DashboardDataProvider provider;

  const _GeographicSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Geographic Insights',
          subtitle: 'Regional activity and trends',
        ),
        const SizedBox(height: 16),
        
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _LocationStatsCard(provider: provider)),
                  const SizedBox(width: 16),
                  Expanded(child: _TopCitiesCard(provider: provider)),
                ],
              );
            } else {
              return Column(
                children: [
                  _LocationStatsCard(provider: provider),
                  const SizedBox(height: 16),
                  _TopCitiesCard(provider: provider),
                ],
              );
            }
          },
        ),
      ],
    );
  }
}

// Content Section
class _ContentSection extends StatelessWidget {
  final DashboardDataProvider provider;

  const _ContentSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1200) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _TopUsersCard(provider: provider),
                    const SizedBox(height: 24),
                    _RecentProductsCard(provider: provider),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _QuickActionsCard(),
                    const SizedBox(height: 24),
                    _RecentActivityCard(provider: provider),
                  ],
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _TopUsersCard(provider: provider),
              const SizedBox(height: 24),
              _RecentProductsCard(provider: provider),
              const SizedBox(height: 24),
              _QuickActionsCard(),
              const SizedBox(height: 24),
              _RecentActivityCard(provider: provider),
            ],
          );
        }
      },
    );
  }
}

// Individual Card Widgets
class _TopSearchesCard extends StatelessWidget {
  final DashboardDataProvider provider;

  const _TopSearchesCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Top Searches',
      subtitle: 'Most searched terms today',
      child: provider.topSearches.isEmpty
          ? const _EmptyState(message: 'No search data available')
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(provider.topSearches.length, 5),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final search = provider.topSearches[index];
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: ArabicTheme.lightGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ArabicTheme.lightGreen,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    search['term'] ?? 'Unknown',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ArabicTheme.textLight,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ArabicTheme.info.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${search['count'] ?? 0}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ArabicTheme.info,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _CategoryTrendsCard extends StatelessWidget {
  final DashboardDataProvider provider;

  const _CategoryTrendsCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Category Trends',
      subtitle: 'Popular categories',
      child: provider.categoryTrends.isEmpty
          ? const _EmptyState(message: 'No category data')
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: provider.categoryTrends
                  .take(5)
                  .map((category) => _CategoryTrendItem(
                        name: category['name'] ?? 'Unknown',
                        count: category['count'] ?? 0,
                        percentage: category['percentage'] ?? 0.0,
                        color: _getCategoryColor(category['name']),
                      ))
                  .toList(),
            ),
    );
  }

  Color _getCategoryColor(String? categoryName) {
    switch (categoryName?.toLowerCase()) {
      case 'mobile':
      case 'phones':
        return ArabicTheme.info;
      case 'cars':
      case 'vehicles':
        return ArabicTheme.warning;
      case 'real estate':
      case 'property':
        return ArabicTheme.gold;
      case 'electronics':
        return ArabicTheme.lightGreen;
      default:
        return ArabicTheme.mediumGreen;
    }
  }
}

class _LocationStatsCard extends StatelessWidget {
  final DashboardDataProvider provider;

  const _LocationStatsCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Location Statistics',
      subtitle: 'Activity by region',
      child: provider.locationData.isEmpty
          ? const _EmptyState(message: 'No location data available')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LocationStatItem(
                  title: 'Total Regions',
                  value: provider.locationData.length.toString(),
                  icon: Icons.location_on,
                  color: ArabicTheme.info,
                ),
                const SizedBox(height: 16),
                _LocationStatItem(
                  title: 'Most Active',
                  value: provider.locationData.isNotEmpty 
                      ? provider.locationData.first['name'] ?? 'Unknown'
                      : 'N/A',
                  icon: Icons.trending_up,
                  color: ArabicTheme.lightGreen,
                ),
                const SizedBox(height: 16),
                _LocationStatItem(
                  title: 'Coverage',
                  value: '${(provider.locationData.length * 15).clamp(0, 100)}%',
                  icon: Icons.public,
                  color: ArabicTheme.gold,
                ),
              ],
            ),
    );
  }
}

class _TopCitiesCard extends StatelessWidget {
      final DashboardDataProvider provider;

  const _TopCitiesCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Top Cities',
      subtitle: 'Most active locations',
      child: provider.topCities.isEmpty
          ? const _EmptyState(message: 'No city data available')
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(provider.topCities.length, 5),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final city = provider.topCities[index];
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ArabicTheme.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.location_city_rounded,
                      color: ArabicTheme.gold,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    city['name'] ?? 'Unknown City',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ArabicTheme.textLight,
                    ),
                  ),
                  subtitle: Text(
                    '${city['userCount'] ?? 0} users • ${city['listingCount'] ?? 0} listings',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: ArabicTheme.textMuted,
                    ),
                  ),
                  trailing: Icon(
                    Icons.trending_up_rounded,
                    color: city['isGrowing'] == true ? ArabicTheme.lightGreen : ArabicTheme.textMuted,
                    size: 16,
                  ),
                );
              },
            ),
    );
  }
}

class _TopUsersCard extends StatelessWidget {
  final DashboardDataProvider provider;

  const _TopUsersCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Top Contributors',
      subtitle: 'Users with most listings',
      child: provider.topUsers.isEmpty
          ? const _EmptyState(message: 'No user data available')
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(provider.topUsers.length, 5),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = provider.topUsers[index];
                final userName = user['companyName'] ?? user['email'] ?? 'Unknown User';
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: ArabicTheme.lightGreen,
                    radius: 20,
                    child: Text(
                      _getInitials(userName),
                      style: GoogleFonts.inter(
                        color: ArabicTheme.textLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  title: Text(
                    userName,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      color: ArabicTheme.textLight,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${user['listingCount'] ?? 0} listings • ${user['type'] == 'company' ? 'Company' : 'Individual'}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: ArabicTheme.textMuted,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getUserBadgeColor(user['listingCount'] ?? 0).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getUserBadge(user['listingCount'] ?? 0),
                      style: GoogleFonts.inter(
                        color: _getUserBadgeColor(user['listingCount'] ?? 0),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _getInitials(String text) {
    if (text.isEmpty) return '?';
    List<String> words = text.trim().split(' ');
    if (words.isEmpty) return '?';
    
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : '?';
    }
    
    String firstInitial = words[0].isNotEmpty ? words[0][0] : '';
    String lastInitial = words[words.length - 1].isNotEmpty ? words[words.length - 1][0] : '';
    
    return (firstInitial + lastInitial).toUpperCase();
  }

  Color _getUserBadgeColor(int listingCount) {
    if (listingCount >= 50) return ArabicTheme.gold;
    if (listingCount >= 20) return ArabicTheme.lightGreen;
    if (listingCount >= 10) return ArabicTheme.info;
    return ArabicTheme.textMuted;
  }

  String _getUserBadge(int listingCount) {
    if (listingCount >= 50) return 'TOP SELLER';
    if (listingCount >= 20) return 'PREMIUM';
    if (listingCount >= 10) return 'ACTIVE';
    return 'NEW';
  }
}

class _RecentProductsCard extends StatelessWidget {
  final DashboardDataProvider provider;

  const _RecentProductsCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Recent Listings',
      subtitle: 'Latest products added',
      child: provider.recentProducts.isEmpty
          ? const _EmptyState(message: 'No recent products')
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(provider.recentProducts.length, 5),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final product = provider.recentProducts[index];
                final imageUrls = product['imageUrls'] as List?;
                
                return ListTile(
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrls != null && imageUrls.isNotEmpty
                          ? Image.network(
                              imageUrls[0],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: ArabicTheme.cardDark,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.image_rounded,
                                    color: ArabicTheme.textMuted,
                                    size: 24,
                                  ),
                                );
                              },
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: ArabicTheme.cardDark,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.image_rounded,
                                color: ArabicTheme.textMuted,
                                size: 24,
                              ),
                            ),
                    ),
                  ),
                  title: Text(
                    product['itemTitle'] ?? 'Unknown Product',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      color: ArabicTheme.textLight,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${product['categoryName'] ?? 'Unknown'} • PKR ${NumberFormat.compact().format(product['price'] ?? 0)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: ArabicTheme.textMuted,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(product['status']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                      style: GoogleFonts.inter(
                        color: _getStatusColor(product['status']),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return ArabicTheme.lightGreen;
      case 'pending':
        return ArabicTheme.warning;
      case 'inactive':
      case 'disabled':
        return ArabicTheme.error;
      default:
        return ArabicTheme.textMuted;
    }
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.add_business_rounded,
        label: 'Add Product',
        color: ArabicTheme.lightGreen,
        onTap: () {}, // Navigate to create product
      ),
      _QuickAction(
        icon: Icons.person_add_rounded,
        label: 'Add User',
        color: ArabicTheme.info,
        onTap: () {}, // Navigate to create user
      ),
      _QuickAction(
        icon: Icons.category_rounded,
        label: 'Categories',
        color: ArabicTheme.warning,
        onTap: () {}, // Navigate to categories
      ),
      _QuickAction(
        icon: Icons.campaign_rounded,
        label: 'Banners',
        color: ArabicTheme.gold,
        onTap: () {}, // Navigate to create banner
      ),
    ];

    return _DashboardCard(
      title: 'Quick Actions',
      subtitle: 'Common tasks',
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: actions,
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
final DashboardDataProvider provider;

  const _RecentActivityCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Recent Activity',
      subtitle: 'Latest system events',
      child: provider.recentActivity.isEmpty
          ? const _EmptyState(message: 'No recent activity')
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(provider.recentActivity.length, 5),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final activity = provider.recentActivity[index];
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _getActivityColor(activity['type']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getActivityIcon(activity['type']),
                      color: _getActivityColor(activity['type']),
                      size: 18,
                    ),
                  ),
                  title: Text(
                    activity['message'] ?? 'Unknown activity',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ArabicTheme.textLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _formatTimeAgo(activity['timestamp']),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: ArabicTheme.textMuted,
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getActivityColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'user_registered':
        return ArabicTheme.lightGreen;
      case 'product_added':
        return ArabicTheme.info;
      case 'chat_started':
        return ArabicTheme.warning;
      case 'support_request':
        return ArabicTheme.error;
      default:
        return ArabicTheme.textMuted;
    }
  }

  IconData _getActivityIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'user_registered':
        return Icons.person_add_rounded;
      case 'product_added':
        return Icons.add_business_rounded;
      case 'chat_started':
        return Icons.chat_bubble_rounded;
      case 'support_request':
        return Icons.support_agent_rounded;
      default:
        return Icons.circle;
    }
  }

  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'Unknown time';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM dd').format(dateTime);
  }
}

// Supporting Widgets
class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArabicTheme.backgroundDark,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: ArabicTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                childAspectRatio: 1.4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: List.generate(4, (index) => Container(
                  decoration: BoxDecoration(
                    color: ArabicTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final double change;
  final String subtitle;
  final bool isRevenue;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.change,
    required this.subtitle,
    this.isRevenue = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change > 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ArabicTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArabicTheme.border.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (change != 0) Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive 
                      ? ArabicTheme.lightGreen.withOpacity(0.2)
                      : ArabicTheme.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 14,
                      color: isPositive ? ArabicTheme.lightGreen : ArabicTheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${change.abs().toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? ArabicTheme.lightGreen : ArabicTheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isRevenue 
                ? 'PKR ${NumberFormat.compact().format(value)}'
                : NumberFormat.compact().format(value),
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ArabicTheme.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ArabicTheme.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: ArabicTheme.textMuted.withOpacity(0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ArabicTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArabicTheme.border.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ArabicTheme.textLight,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: ArabicTheme.textMuted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ArabicTheme.textLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: ArabicTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ArabicTheme.textLight,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: ArabicTheme.textLight.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryTrendItem extends StatelessWidget {
  final String name;
  final int count;
  final double percentage;
  final Color color;

  const _CategoryTrendItem({
    required this.name,
    required this.count,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ArabicTheme.textLight,
                  ),
                ),
              ),
              Text(
                count.toString(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: ArabicTheme.border.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}

class _LocationStatItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _LocationStatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: ArabicTheme.textMuted,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ArabicTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ArabicTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArabicTheme.border.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ArabicTheme.textLight,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;

  const _EmptyState({
    required this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.inbox_rounded,
              size: 48,
              color: ArabicTheme.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: ArabicTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// SafeStateMixin - Add this to your existing file or create a new utilities file
mixin SafeStateMixin<T extends StatefulWidget> on State<T> {
  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void safeSetState(VoidCallback fn) {
    if (_mounted && mounted) {
      setState(fn);
    }
  }

  void postFrameCallback(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mounted && mounted) {
        callback();
      }
    });
  }
}

// SafeStringUtils - Helper for safe string operations
class SafeStringUtils {
  static String safeSubstring(String text, int start, [int? end]) {
    if (text.isEmpty) return '';
    
    int safeStart = start.clamp(0, text.length);
    
    if (end == null) {
      return text.substring(safeStart);
    }
    
    int safeEnd = end.clamp(safeStart, text.length);
    return text.substring(safeStart, safeEnd);
  }
  
  static String getInitials(String text) {
    if (text.isEmpty) return '?';
    
    List<String> words = text.trim().split(' ');
    if (words.isEmpty) return '?';
    
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : '?';
    }
    
    String firstInitial = words[0].isNotEmpty ? words[0][0] : '';
    String lastInitial = words[words.length - 1].isNotEmpty ? words[words.length - 1][0] : '';
    
    return (firstInitial + lastInitial).toUpperCase();
  }
}

// SafeNetworkImage - Safe image loading widget
class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SafeNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return placeholder ?? Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(
            Icons.broken_image_outlined,
            color: Colors.grey,
          ),
        );
      },
    );
  }
}

// Layout Helper Widget - Use this to ensure proper constraints
class ConstrainedContainer extends StatelessWidget {
  final Widget child;
  final double? minWidth;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;

  const ConstrainedContainer({
    Key? key,
    required this.child,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.padding,
    this.margin,
    this.decoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: decoration,
      constraints: BoxConstraints(
        minWidth: minWidth ?? 0,
        maxWidth: maxWidth ?? double.infinity,
        minHeight: minHeight ?? 0,
        maxHeight: maxHeight ?? double.infinity,
      ),
      child: child,
    );
  }
}

// Safe Builder Widget - Prevents layout errors
class SafeBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints) builder;
  final Widget? fallback;

  const SafeBuilder({
    Key? key,
    required this.builder,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        try {
          if (constraints.maxWidth.isInfinite || 
              constraints.maxHeight.isInfinite ||
              constraints.maxWidth <= 0 ||
              constraints.maxHeight <= 0) {
            return fallback ?? const SizedBox.shrink();
          }
          return builder(context, constraints);
        } catch (e) {
          debugPrint('SafeBuilder error: $e');
          return fallback ?? Container(
            width: 100,
            height: 100,
            color: Colors.red[100],
            child: const Center(
              child: Icon(Icons.error, color: Colors.red),
            ),
          );
        }
      },
    );
  }
}

// Responsive Grid Helper
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int minItemsPerRow;
  final int maxItemsPerRow;
  final double itemAspectRatio;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.minItemsPerRow = 1,
    this.maxItemsPerRow = 4,
    this.itemAspectRatio = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate number of items per row based on available width
        double availableWidth = constraints.maxWidth;
        int itemsPerRow = maxItemsPerRow;
        
        // Minimum item width calculation
        double minItemWidth = 200; // Adjust based on your needs
        int maxPossibleItems = (availableWidth / minItemWidth).floor();
        
        itemsPerRow = maxPossibleItems.clamp(minItemsPerRow, maxItemsPerRow);
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: itemsPerRow,
            childAspectRatio: itemAspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

// Safe ListView Builder
class SafeListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Widget? separator;

  const SafeListView({
    Key? key,
    required this.children,
    this.padding,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.separator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    if (separator != null) {
      return ListView.separated(
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: padding,
        itemCount: children.length,
        separatorBuilder: (context, index) => separator!,
        itemBuilder: (context, index) => children[index],
      );
    }

    return ListView(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      children: children,
    );
  }
}

// Theme-aware Container
class ThemedContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final double borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;

  const ThemedContainer({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.backgroundColor,
    this.borderRadius = 16,
    this.borderColor,
    this.borderWidth = 1,
    this.boxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null 
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Responsive Row/Column
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final double breakpoint;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double spacing;

  const ResponsiveRowColumn({
    Key? key,
    required this.children,
    this.breakpoint = 600,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > breakpoint;
        
        if (isWide) {
          return Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: _addSpacing(children, true),
          );
        } else {
          return Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: _addSpacing(children, false),
          );
        }
      },
    );
  }

  List<Widget> _addSpacing(List<Widget> children, bool isRow) {
    if (children.isEmpty) return children;
    
    List<Widget> spacedChildren = [];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(
          isRow 
              ? SizedBox(width: spacing)
              : SizedBox(height: spacing),
        );
      }
    }
    return spacedChildren;
  }
}

// Error Boundary Widget
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error)? errorBuilder;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ?? 
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Something went wrong: $_error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() => _error = null),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
    }

    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FlutterError.onError = (FlutterErrorDetails details) {
      setState(() {
        _error = details.exception;
      });
    };
  }
}

// Shimmer Loading Widget
class ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const ShimmerBox({
    Key? key,
    this.width,
    this.height,
    this.borderRadius = 8,
  }) : super(key: key);

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

// Loading States
class LoadingCard extends StatelessWidget {
  final double? width;
  final double? height;

  const LoadingCard({Key? key, this.width, this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ThemedContainer(
      width: width,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            width: double.infinity,
            height: 20,
            borderRadius: 4,
          ),
          const SizedBox(height: 12),
          ShimmerBox(
            width: 150,
            height: 16,
            borderRadius: 4,
          ),
          const SizedBox(height: 8),
          ShimmerBox(
            width: 100,
            height: 16,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }
}