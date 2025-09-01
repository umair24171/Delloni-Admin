import 'package:delloniweb/controllers/admin_auth_provider.dart';
import 'package:delloniweb/resources/colors.dart';
import 'package:delloniweb/screens/chat_management_screen.dart';
import 'package:delloniweb/screens/dashboard_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';


class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArabicTheme.backgroundDark,
              ArabicTheme.primaryGreen,
              ArabicTheme.mediumGreen,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: Card(
                        elevation: 20,
                        shadowColor: ArabicTheme.shadow.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        color: ArabicTheme.surfaceDark,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: ArabicTheme.border.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo and Title
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [ArabicTheme.gold, ArabicTheme.lightGold],
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: ArabicTheme.gold.withOpacity(0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/icons/new_app_logo.png',
                                    height: 50,
                                    width: 50,
                                    fit: BoxFit.cover,
                                    // color: ArabicTheme.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  'Admin Panel',
                                  style: GoogleFonts.inter(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: ArabicTheme.textLight,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Delloni Dashboard',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: ArabicTheme.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                
                                // Login Form
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      // Email Field
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: ArabicTheme.border.withOpacity(0.3),
                                          ),
                                          color: ArabicTheme.cardDark,
                                        ),
                                        child: TextFormField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          style: GoogleFonts.inter(
                                          color: Colors.black,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Email Address',
                                            labelStyle: GoogleFonts.inter(
                                              color: ArabicTheme.textMuted,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.email_outlined,
                                              color: ArabicTheme.lightGreen,
                                            ),
                                            hintText: 'Enter your admin email',
                                            hintStyle: GoogleFonts.inter(
                                              color: ArabicTheme.textMuted.withOpacity(0.7),
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 20,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your email';
                                            }
                                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                              return 'Please enter a valid email';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      // Password Field
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: ArabicTheme.border.withOpacity(0.3),
                                          ),
                                          color: ArabicTheme.cardDark,
                                        ),
                                        child: TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          style: GoogleFonts.inter(
                                           color: Colors.black,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Password',
                                            labelStyle: GoogleFonts.inter(
                                              color: ArabicTheme.textMuted,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.lock_outlined,
                                              color: ArabicTheme.lightGreen,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword 
                                                    ? Icons.visibility_outlined 
                                                    : Icons.visibility_off_outlined,
                                                color: ArabicTheme.textMuted,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword = !_obscurePassword;
                                                });
                                              },
                                            ),
                                            hintText: 'Enter your password',
                                            hintStyle: GoogleFonts.inter(
                                              color: ArabicTheme.textMuted.withOpacity(0.7),
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 20,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your password';
                                            }
                                            if (value.length < 6) {
                                              return 'Password must be at least 6 characters';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      // Remember Me & Forgot Password
                                      Row(
                                        children: [
                                          Theme(
                                            data: Theme.of(context).copyWith(
                                              unselectedWidgetColor: ArabicTheme.textMuted,
                                            ),
                                            child: Checkbox(
                                              value: _rememberMe,
                                              onChanged: (value) {
                                                setState(() {
                                                  _rememberMe = value ?? false;
                                                });
                                              },
                                              activeColor: ArabicTheme.lightGreen,
                                              checkColor: ArabicTheme.textLight,
                                            ),
                                          ),
                                          Text(
                                            'Remember me',
                                            style: GoogleFonts.inter(
                                              color: ArabicTheme.textMedium,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const Spacer(),
                                          TextButton(
                                            onPressed: () {
                                              _showForgotPasswordDialog();
                                            },
                                            child: Text(
                                              'Forgot Password?',
                                              style: GoogleFonts.inter(
                                                color: ArabicTheme.lightGold,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 32),
                                      
                                      // Login Button
                                      Consumer<AdminAuthProvider>(
                                        builder: (context, authProvider, child) {
                                          return Container(
                                            width: double.infinity,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: authProvider.isLoading
                                                    ? [ArabicTheme.textMuted, ArabicTheme.textMuted]
                                                    : [ArabicTheme.lightGreen, ArabicTheme.accentGreen],
                                              ),
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: authProvider.isLoading ? null : [
                                                BoxShadow(
                                                  color: ArabicTheme.lightGreen.withOpacity(0.4),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              onPressed: authProvider.isLoading ? null : _handleLogin,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: authProvider.isLoading
                                                  ? SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2.5,
                                                        valueColor: AlwaysStoppedAnimation<Color>(
                                                          ArabicTheme.textLight,
                                                        ),
                                                      ),
                                                    )
                                                  : Text(
                                                      'Sign In',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.w700,
                                                        color: ArabicTheme.textLight,
                                                      ),
                                                    ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 28),
                                
                                // Error Message
                                Consumer<AdminAuthProvider>(
                                  builder: (context, authProvider, child) {
                                    if (authProvider.error != null) {
                                      return Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: ArabicTheme.error.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: ArabicTheme.error.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline_rounded,
                                              color: ArabicTheme.error,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                authProvider.error!,
                                                style: GoogleFonts.inter(
                                                  color: ArabicTheme.error,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
      await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ArabicTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Reset Password',
          style: GoogleFonts.inter(
            color: ArabicTheme.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address to receive password reset instructions.',
              style: GoogleFonts.inter(
                color: ArabicTheme.textMedium,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ArabicTheme.border.withOpacity(0.3),
                ),
                color: ArabicTheme.cardDark,
              ),
              child: TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.inter(
                  color: Colors.black,
                ),
                decoration: InputDecoration(

                  labelText: 'Email Address',
                  labelStyle: GoogleFonts.inter(
                    color: ArabicTheme.textMuted,
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: ArabicTheme.lightGreen,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: ArabicTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ArabicTheme.lightGreen, ArabicTheme.accentGreen],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Password reset instructions sent to your email',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: ArabicTheme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Send Reset Link',
                style: GoogleFonts.inter(
                  color: ArabicTheme.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}