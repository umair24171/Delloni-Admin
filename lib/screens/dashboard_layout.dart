import 'package:delloniweb/controllers/admin_auth_provider.dart';
import 'package:delloniweb/controllers/admin_data_provider.dart';
import 'package:delloniweb/providers/admin_data_provider.dart';
import 'package:delloniweb/resources/colors.dart';
import 'package:delloniweb/screens/admin_chat_dashboard.dart';
import 'package:delloniweb/screens/banners_screen.dart';
import 'package:delloniweb/screens/categories_management_screen.dart';
import 'package:delloniweb/screens/chat_management_screen.dart';
import 'package:delloniweb/screens/chat_reports.dart';
import 'package:delloniweb/screens/city_management_screen.dart';
import 'package:delloniweb/screens/create_banner_screen.dart';
import 'package:delloniweb/screens/create_product_screen.dart';
import 'package:delloniweb/screens/dashboard_overview.dart';
import 'package:delloniweb/screens/field_template_management_screen.dart';
import 'package:delloniweb/screens/notiifications_page.dart';
import 'package:delloniweb/screens/product_management_screen.dart';
import 'package:delloniweb/screens/support_requesrt_screen.dart';
import 'package:delloniweb/screens/users_management_screen.dart';
import 'package:delloniweb/screens/widgets/notifications_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Using the same Arabic Theme
class ArabicTheme {
  // Dark Green Palette
  static const Color primaryDark = Color(0xFF0B1F0F);
  static const Color primaryGreen = Color(0xFF1B4332);
  static const Color mediumGreen = Color(0xFF2D5016);
  static const Color lightGreen = Color(0xFF40916C);
  static const Color accentGreen = Color(0xFF52B788);
  
  // Gold Accents
  static const Color gold = Color(0xFFDAA520);
  static const Color lightGold = Color(0xFFFFD700);
  
  // Background Colors
  static const Color backgroundDark = Color(0xFF081C15);
  static const Color surfaceDark = Color(0xFF1B4332);
  static const Color cardDark = Color(0xFF2D5016);
  static const Color overlayDark = Color(0xFF40916C);
  
  // Text Colors
  static const Color textLight = Color(0xFFF1F8E9);
  static const Color textMedium = Color(0xFFC8E6C9);
  static const Color textDark = Color(0xFF81C784);
  static const Color textMuted = Color(0xFF66BB6A);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Border and Shadow
  static const Color border = Color(0xFF2D5016);
  static const Color shadow = Color(0xFF000000);
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}
class _AdminDashboardState extends State<AdminDashboard> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;
  late AnimationController _screenTransitionController;
  late Animation<double> _screenTransitionAnimation;
  
  // Cache widgets to prevent rebuilds
  Widget? _cachedSidebar;
  Widget? _cachedTopBar;
  // Remove the _cachedScreens map to allow dynamic screen colors
  
  // Screen background colors for each screen
  static final Map<int, Color> _screenColors = {
    0: ArabicTheme.surfaceDark,           // Dashboard
    1: ArabicTheme.cardDark,              // Ads Management
    2: ArabicTheme.mediumGreen,           // Create Ad
    3: ArabicTheme.primaryGreen,          // Chat Management
    4: ArabicTheme.overlayDark,           // Users
    5: ArabicTheme.lightGreen,            // Categories
    6: ArabicTheme.error.withOpacity(0.1), // Support
    7: ArabicTheme.gold.withOpacity(0.1), // Banners
    8: ArabicTheme.gold.withOpacity(0.2), // Create Banner
    9: ArabicTheme.info.withOpacity(0.1), // Cities
  };

  // Dashboard items list
  static final List<DashboardItem> _dashboardItems = [
    DashboardItem(
      index: 0,
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      gradient: [ArabicTheme.lightGreen, ArabicTheme.accentGreen],
    ),
    DashboardItem(
      index: 1,
      title: 'Ads Management',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
      gradient: [ArabicTheme.mediumGreen, ArabicTheme.lightGreen],
    ),
    DashboardItem(
      index: 2,
      title: 'Create Ad',
      icon: Icons.add_circle_outline,
      selectedIcon: Icons.add_circle_rounded,
      gradient: [ArabicTheme.accentGreen, ArabicTheme.lightGreen],
    ),
    DashboardItem(
      index: 3,
      title: 'Chat Management',
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble_rounded,
      hasSubmenu: true,
      submenuItems: [
        SubmenuItem(title: 'All Chats', index: 3),
        SubmenuItem(title: 'Reports', index: 10),
      ],
      gradient: [ArabicTheme.primaryGreen, ArabicTheme.mediumGreen],
    ),
    DashboardItem(
      index: 4,
      title: 'Users',
      icon: Icons.people_outline,
      selectedIcon: Icons.people_rounded,
      gradient: [ArabicTheme.overlayDark, ArabicTheme.lightGreen],
    ),
    DashboardItem(
      index: 5,
      title: 'Categories',
      icon: Icons.category_outlined,
      selectedIcon: Icons.category_rounded,
      gradient: [ArabicTheme.lightGreen, ArabicTheme.accentGreen],
    ),
    DashboardItem(
      index: 6,
      title: 'Field Templates',
      icon: Icons.category_outlined,
      selectedIcon: Icons.category_rounded,
      gradient: [ArabicTheme.lightGreen, ArabicTheme.accentGreen],
    ),
    DashboardItem(
      index: 7,
      title: 'Support',
      icon: Icons.support_agent_outlined,
      selectedIcon: Icons.support_agent_rounded,
      gradient: [ArabicTheme.error, ArabicTheme.error.withOpacity(0.8)],
    ),
    DashboardItem(
      index: 8,
      title: 'Banners',
      icon: Icons.image_outlined,
      selectedIcon: Icons.image_rounded,
      gradient: [ArabicTheme.gold, ArabicTheme.lightGold],
    ),
    DashboardItem(
      index: 9,
      title: 'Create Banner',
      icon: Icons.add_photo_alternate_outlined,
      selectedIcon: Icons.add_photo_alternate_rounded,
      gradient: [ArabicTheme.lightGold, ArabicTheme.gold],
    ),
    DashboardItem(
      index: 10,
      title: 'Reports',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics_rounded,
      gradient: [ArabicTheme.info, ArabicTheme.info.withOpacity(0.8)],
    ),
    DashboardItem(
      index: 11,
      title: 'Cities',
      icon: Icons.location_city_outlined,
      selectedIcon: Icons.location_city_rounded,
      gradient: [ArabicTheme.info, ArabicTheme.info.withOpacity(0.8)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardDataAsync();
      Provider.of<DashboardDataProvider>(context, listen: false).initializeAdminData();
    });
  }

  void _initializeAnimations() {
    _sidebarController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _sidebarAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _sidebarController, 
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Add screen transition animation
    _screenTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _screenTransitionAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _screenTransitionController,
        curve: Curves.easeInOutCubic,
      ),
    );
    
    _sidebarController.forward();
    _screenTransitionController.forward();
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    _screenTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: ArabicTheme.backgroundDark,
      body: Row(
        children: [
          _buildCachedSidebar(),
          
          // Main Content with Dynamic Background
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: ArabicTheme.backgroundDark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  _buildCachedTopBar(),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        // Dynamic background color based on selected screen
                        color: _screenColors[_selectedIndex] ?? ArabicTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ArabicTheme.border.withOpacity(0.3)
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_screenColors[_selectedIndex] ?? ArabicTheme.surfaceDark)
                                .withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _buildDynamicMainContent(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build dynamic main content without caching to allow color changes
  Widget _buildDynamicMainContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(
              Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ),
            ),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(_selectedIndex), // Important: Key ensures proper rebuilding
        width: double.infinity,
        height: double.infinity,
        child: _getScreenForIndex(_selectedIndex),
      ),
    );
  }

  // Event handlers with animation
  void _onNavItemTap(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      
      // Trigger screen transition animation
      _screenTransitionController.reset();
      _screenTransitionController.forward();
    }
  }

  void _onSubmenuTap(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      
      // Trigger screen transition animation
      _screenTransitionController.reset();
      _screenTransitionController.forward();
    }
  }
  

  // Individual screen widgets with proper background colors
  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return _ScreenWrapper(
          backgroundColor: Colors.transparent, // Let parent handle background
          child: const DashboardOverview(),
        );
      case 1:
        return _ScreenWrapper(
          backgroundColor: Colors.transparent,
          child: const ProductsScreen(),
        );
      case 2:
        return _ScreenWrapper(
          backgroundColor: Colors.transparent,
          child: const CreateProductScreen(),
        );
      case 3:
        return _ScreenWrapper(
          backgroundColor: Colors.transparent,
          child: const AdminChatDashboard(),
        );
      case 4:
        return _ScreenWrapper(
          backgroundColor: Colors.transparent,
          child: const UsersScreen(),
        );
      case 5:
        return _ScreenWrapper(
          backgroundColor: Colors.transparent,
          child: const CategoriesManagementScreen(),
        );
      case 6:
        return _ScreenWrapper(
          backgroundColor: ArabicTheme.cardDark,
          child: const CategoryFieldManagementScreen(),
        );
      case 7:
        return _ScreenWrapper(
          backgroundColor: Colors.transparent,
          child: const SupportRequestsScreen(),
        );
      case  8:
        return _ScreenWrapper(
          backgroundColor: Colors.transparent,
          child: const BannersScreen(),
        );
      case 9:
        return _ScreenWrapper(
          backgroundColor: Colors.transparent,
          child: const CreateBannerScreen(),
        );
      case 10:
        return _ScreenWrapper(
          backgroundColor: Colors.transparent,
          child: const ReportsManagementScreen(),
        );
      case 11:
        return _ScreenWrapper(
          backgroundColor: Colors.transparent,
          child: const CitiesManagementPage(),
        );
      default:
        return _ScreenWrapper(
          backgroundColor: Colors.transparent,
          child: const DashboardOverview(),
        );
    }
  }

  // Rest of your existing methods remain the same...
  // (buildCachedSidebar, buildOptimizedSidebar, etc.)
  
  void _loadDashboardDataAsync() {
    Future.microtask(() {
      final provider = Provider.of<DashboardDataProvider>(context, listen: false);
      if (mounted) {
        provider.loadDashboardData();
      }
    });
  }

  Widget _buildCachedSidebar() {
    if (_cachedSidebar == null || _isSidebarExpanded != _previousSidebarState) {
      _cachedSidebar = AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: _isSidebarExpanded ? 300 : 80,
        child: _buildOptimizedSidebar(),
      );
      _previousSidebarState = _isSidebarExpanded;
    }
    return _cachedSidebar!;
  }

  bool _previousSidebarState = true;

  Widget _buildOptimizedSidebar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.white,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: ArabicTheme.shadow.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLogoSection(),
          
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ListView.builder(
                itemCount: _AdminDashboardState._dashboardItems.length,
                itemBuilder: (context, index) {
                  return _OptimizedNavItem(
                    item: _AdminDashboardState._dashboardItems[index],
                    isSelected: _selectedIndex == _AdminDashboardState._dashboardItems[index].index,
                    isSidebarExpanded: _isSidebarExpanded,
                    selectedSubmenuIndex: _selectedIndex,
                    onTap: _onNavItemTap,
                    onSubmenuTap: _onSubmenuTap,
                  );
                },
              ),
            ),
          ),
          
          _buildOptimizedAdminProfile(),
        ],
      ),
    );
  }

  // Add other missing methods from your original code...
  Widget _buildLogoSection() {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white,
          ],
          // colors: [ArabicTheme.gold, ArabicTheme.lightGold],
        ),
        boxShadow: [
          BoxShadow(
            color: ArabicTheme.gold.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'app_logo',
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: ArabicTheme.primaryDark,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: ArabicTheme.primaryDark.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/icons/new_app_logo.png',
                  height: 50,
                  width: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.admin_panel_settings,
                      color: ArabicTheme.gold,
                      size: 24,
                    );
                  },
                ),
              ),
            ),
          ),
          if (_isSidebarExpanded) ...[
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Admin Panel',
                    style: GoogleFonts.inter(
                      color: ArabicTheme.primaryDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Delloni',
                    style: GoogleFonts.inter(
                      color: ArabicTheme.primaryDark.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCachedTopBar() {
    final String cacheKey = '${_selectedIndex}_${_isSidebarExpanded}';
    if (_cachedTopBar == null || _lastTopBarCacheKey != cacheKey) {
      _cachedTopBar = _buildOptimizedTopBar();
      _lastTopBarCacheKey = cacheKey;
    }
    return _cachedTopBar!;
  }

  String _lastTopBarCacheKey = '';

  Widget _buildOptimizedTopBar() {
    return Container(
      height: 80,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ArabicTheme.border.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: ArabicTheme.shadow.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            _SidebarToggleButton(
              isExpanded: _isSidebarExpanded,
              onPressed: _toggleSidebar,
            ),
            
            const SizedBox(width: 24),
            
            _PageTitleWidget(selectedIndex: _selectedIndex),
            
            const Spacer(),
            
            const NotificationCounterWidget(),
            
            const SizedBox(width: 16),
            
            _AdminProfileMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizedAdminProfile() {
    return Consumer<AdminAuthProvider>(
      builder: (context, authProvider, child) {
        if (!_isSidebarExpanded) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: ArabicTheme.error.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _showEnhancedLogoutDialog,
                icon: const Icon(
                  Icons.logout_outlined,
                  color: ArabicTheme.error,
                ),
              ),
            ),
          );
        }
        
        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ArabicTheme.cardDark, ArabicTheme.mediumGreen],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ArabicTheme.border.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: ArabicTheme.shadow.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ArabicTheme.gold, ArabicTheme.lightGold],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: ArabicTheme.gold.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    authProvider.currentAdmin?.companyName?.substring(0, 1).toUpperCase() ?? 'A',
                    style: GoogleFonts.inter(
                      color: ArabicTheme.primaryDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      authProvider.currentAdmin?.companyName ?? 'Admin',
                      style: GoogleFonts.inter(
                        color: ArabicTheme.textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      authProvider.currentAdmin?.email ?? '',
                      style: GoogleFonts.inter(
                        color: ArabicTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: ArabicTheme.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: _showEnhancedLogoutDialog,
                  icon: const Icon(
                    Icons.logout_outlined,
                    color: ArabicTheme.error,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  void _showEnhancedLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ArabicTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ArabicTheme.error.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.logout_outlined,
                color: ArabicTheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Confirm Logout',
              style: GoogleFonts.inter(
                color: ArabicTheme.textLight,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Are you sure you want to logout? You will need to sign in again to access the admin panel.',
            style: GoogleFonts.inter(
              color: ArabicTheme.textMedium,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: ArabicTheme.border.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: ArabicTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ArabicTheme.error, ArabicTheme.error.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ArabicTheme.error.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<AdminAuthProvider>(context, listen: false).signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.logout_outlined,
                    color: ArabicTheme.textLight,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: GoogleFonts.inter(
                      color: ArabicTheme.textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

// Optimized Navigation Item Widget
class _OptimizedNavItem extends StatelessWidget {
  final DashboardItem item;
  final bool isSelected;
  final bool isSidebarExpanded;
  final int selectedSubmenuIndex;
  final Function(int) onTap;
  final Function(int) onSubmenuTap;

  const _OptimizedNavItem({
    required this.item,
    required this.isSelected,
    required this.isSidebarExpanded,
    required this.selectedSubmenuIndex,
    required this.onTap,
    required this.onSubmenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onTap(item.index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: isSelected 
                      ? LinearGradient(colors: item.gradient!)
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected ? null : Border.all(
                    color: ArabicTheme.border.withOpacity(0.2),
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: item.gradient!.first.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ] : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? ArabicTheme.textLight.withOpacity(0.2)
                            : ArabicTheme.textLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        color: isSelected ? ArabicTheme.textLight : ArabicTheme.textMuted,
                        size: 20,
                      ),
                    ),
                    if (isSidebarExpanded) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.inter(
                            color: isSelected ? ArabicTheme.textLight : ArabicTheme.textMuted,
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (item.hasSubmenu)
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isSelected ? ArabicTheme.textLight : ArabicTheme.textMuted,
                          size: 20,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Submenu items
          if (item.hasSubmenu && isSidebarExpanded && isSelected) ...[
            const SizedBox(height: 8),
            ...item.submenuItems!.map((submenu) => Container(
              margin: const EdgeInsets.only(left: 20, right: 8, bottom: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSubmenuTap(submenu.index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selectedSubmenuIndex == submenu.index 
                          ? ArabicTheme.textLight.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: selectedSubmenuIndex == submenu.index
                                ? ArabicTheme.textLight
                                : ArabicTheme.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          submenu.title,
                          style: GoogleFonts.inter(
                            color: selectedSubmenuIndex == submenu.index
                                ? ArabicTheme.textLight
                                : ArabicTheme.textMuted,
                            fontSize: 13,
                            fontWeight: selectedSubmenuIndex == submenu.index
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
}

// Sidebar Toggle Button Widget
class _SidebarToggleButton extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onPressed;

  const _SidebarToggleButton({
    required this.isExpanded,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ArabicTheme.lightGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: AnimatedRotation(
          turns: isExpanded ? 0 : 0.5,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.menu_rounded),
        ),
        color: ArabicTheme.lightGreen,
      ),
    );
  }
}

// Page Title Widget
class _PageTitleWidget extends StatelessWidget {
  final int selectedIndex;

  const _PageTitleWidget({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _getPageTitle(selectedIndex),
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: ArabicTheme.backgroundDark,
          ),
        ),
        Text(
          'Manage your marketplace',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: ArabicTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0: return 'Dashboard Overview';
      case 1: return 'Ads Management';
      case 2: return 'Create New Product';
      case 3: return 'Chat Management';
      case 4: return 'Users Management';
      case 5: return 'Categories Management';
      case 6: return 'Field Templates';   
      case 7: return 'Support Requests';
      case 8: return 'Banners Management';
      case 9: return 'Create New Banner';
      case 10: return 'Reports';
      case 11: return 'Cities Management';
      default: return 'Dashboard';
    }
  }
}

// Admin Profile Menu Widget
class _AdminProfileMenu extends StatelessWidget {
  const _AdminProfileMenu();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminAuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ArabicTheme.gold, ArabicTheme.lightGold],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ArabicTheme.gold.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: ArabicTheme.surfaceDark,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 18, color: ArabicTheme.lightGreen),
                    const SizedBox(width: 12),
                    Text('Profile', style: GoogleFonts.inter(color: ArabicTheme.textLight)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18, color: ArabicTheme.info),
                    const SizedBox(width: 12),
                    Text('Settings', style: GoogleFonts.inter(color: ArabicTheme.textLight)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_outlined, size: 18, color: ArabicTheme.error),
                    const SizedBox(width: 12),
                    Text('Logout', style: GoogleFonts.inter(color: ArabicTheme.error)),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: ArabicTheme.primaryDark,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ArabicTheme.primaryDark.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        authProvider.currentAdmin?.companyName?.substring(0, 1).toUpperCase() ?? 'A',
                        style: GoogleFonts.inter(
                          color: ArabicTheme.gold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        authProvider.currentAdmin?.companyName ?? 'Admin',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ArabicTheme.primaryDark,
                        ),
                      ),
                      Text(
                        'Administrator',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: ArabicTheme.primaryDark.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: ArabicTheme.primaryDark,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ArabicTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ArabicTheme.error.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.logout_outlined,
                color: ArabicTheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Confirm Logout',
              style: GoogleFonts.inter(
                color: ArabicTheme.textLight,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Are you sure you want to logout? You will need to sign in again to access the admin panel.',
            style: GoogleFonts.inter(
              color: ArabicTheme.textMedium,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: ArabicTheme.border.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: ArabicTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ArabicTheme.error, ArabicTheme.error.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ArabicTheme.error.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<AdminAuthProvider>(context, listen: false).signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.logout_outlined,
                    color: ArabicTheme.textLight,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: GoogleFonts.inter(
                      color: ArabicTheme.textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Cached Screen Wrapper for better performance
class _CachedScreenWrapper extends StatefulWidget {
  final Widget child;

  const _CachedScreenWrapper({required this.child});

  @override
  State<_CachedScreenWrapper> createState() => _CachedScreenWrapperState();
}

class _CachedScreenWrapperState extends State<_CachedScreenWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// Data models remain the same
class DashboardItem {
  final int index;
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final bool hasSubmenu;
  final List<SubmenuItem>? submenuItems;
  final List<Color>? gradient;

  const DashboardItem({
    required this.index,
    required this.title,
    required this.icon,
    required this.selectedIcon,
    this.hasSubmenu = false,
    this.submenuItems,
    this.gradient,
  });
}

class SubmenuItem {
  final String title;
  final int index;

  const SubmenuItem({
    required this.title,
    required this.index,
  });
}
class _ScreenWrapper extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;

  const _ScreenWrapper({
    required this.child,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor,
      child: child,
    );
  }
}