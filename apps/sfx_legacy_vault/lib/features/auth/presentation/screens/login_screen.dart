import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_legacy_vault/core/constants/app_colors.dart';
import 'package:sfx_legacy_vault/features/auth/presentation/providers/auth_provider.dart';
import 'package:sfx_legacy_vault/features/vault/presentation/screens/home_screen.dart';

/// Login / Sign Up screen - Premium dark theme with neon accents
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _shieldPulseController;

  @override
  void initState() {
    super.initState();
    _shieldPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shieldPulseController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(firebaseAuthProvider);

      if (_isLogin) {
        await service.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await service.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = _formatError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatError(String rawError) {
    if (rawError.contains('user-not-found')) {
      return 'No account found with this email.';
    }
    if (rawError.contains('wrong-password')) {
      return 'Incorrect password.';
    }
    if (rawError.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (rawError.contains('weak-password')) {
      return 'Password should be at least 6 characters.';
    }
    if (rawError.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    return 'Authentication failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background glow effects
          Positioned(
            top: -100,
            right: -100,
            child: _GlowOrb(
              color: AppColors.neonGreen.withValues(alpha:0.06),
              radius: 250,
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _GlowOrb(
              color: AppColors.neonCyan.withValues(alpha:0.05),
              radius: 200,
            ),
          ),
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),

                      // Shield hero icon with glow animation
                      _buildShieldHero(),
                      const SizedBox(height: 16),

                      // Tagline
                      const Text(
                        'Protected by Military-Grade Encryption',
                        style: TextStyle(
                          color: AppColors.neonCyan,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 500.ms),
                      const SizedBox(height: 8),

                      // "암호화된 보호" badge
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.neonGreen.withValues(alpha:0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.neonGreen.withValues(alpha:0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded,
                                size: 14, color: AppColors.neonGreen),
                            const SizedBox(width: 6),
                            const Text(
                              '암호화된 보호',
                              style: TextStyle(
                                color: AppColors.neonGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 500.ms, duration: 500.ms),
                      const SizedBox(height: 36),

                      // Form title
                      Text(
                        _isLogin ? 'Welcome Back' : 'Create Your Vault',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 500.ms),
                      const SizedBox(height: 6),
                      Text(
                        _isLogin
                            ? 'Sign in to access your encrypted vault'
                            : "Set up your dead man's switch",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: 350.ms, duration: 500.ms),
                      const SizedBox(height: 32),

                      // Email field with neon border
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 500.ms)
                          .slideX(begin: -0.3, end: 0, duration: 500.ms),
                      const SizedBox(height: 14),

                      // Password field with neon border
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (!_isLogin && value.length < 6) {
                            return 'At least 6 characters';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(delay: 500.ms, duration: 500.ms)
                          .slideX(begin: 0.3, end: 0, duration: 500.ms),

                      // "계정 찾기" / "비밀번호 재설정" links
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () {
                                // TODO: Implement account recovery
                              },
                              child: Text(
                                '계정 찾기',
                                style: TextStyle(
                                  color: AppColors.neonCyan.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 12,
                              color: AppColors.surfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                // TODO: Implement password reset
                              },
                              child: Text(
                                '비밀번호 재설정',
                                style: TextStyle(
                                  color: AppColors.neonCyan.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Error message
                      if (_errorMessage != null)
                        _buildErrorMessage(_errorMessage!)
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .shake(duration: 400.ms),
                      SizedBox(height: _errorMessage != null ? 4 : 16),

                      // Submit button with glow
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow behind button
                          Container(
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.neonGreen.withValues(alpha:0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          // Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleAuth,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.background,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isLogin
                                            ? Icons.login_rounded
                                            : Icons.vpn_key_rounded,
                                        size: 20,
                                        color: AppColors.background,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isLogin ? 'Sign In' : 'Create Vault',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(delay: 700.ms, duration: 500.ms),
                      const SizedBox(height: 24),

                      // Divider
                      _buildDivider()
                          .animate()
                          .fadeIn(delay: 800.ms, duration: 500.ms),
                      const SizedBox(height: 20),

                      // Apple Sign-In button with proper styling
                      _buildAppleSignInButton()
                          .animate()
                          .fadeIn(delay: 850.ms, duration: 500.ms),
                      const SizedBox(height: 24),

                      // Toggle text
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _errorMessage = null;
                                });
                              },
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: _isLogin
                                    ? "Don't have an account? "
                                    : 'Already have an account? ',
                              ),
                              TextSpan(
                                text: _isLogin ? 'Sign Up' : 'Sign In',
                                style: const TextStyle(
                                  color: AppColors.neonPink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 950.ms, duration: 500.ms),

                      // Bottom security note
                      const SizedBox(height: 12),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha:0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'All data encrypted client-side with AES-256. We never see your data.',
                                style: TextStyle(
                                  color: AppColors.textSecondary.withValues(alpha:0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 1000.ms, duration: 500.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shield hero icon with pulsing glow animation
  Widget _buildShieldHero() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing glow
          AnimatedBuilder(
            animation: _shieldPulseController,
            builder: (context, child) {
              final scale = 1.0 + _shieldPulseController.value * 0.25;
              final opacity = 0.08 + (1.0 - _shieldPulseController.value) * 0.07;
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.neonGreen.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Middle ring
          SizedBox(
            width: 84,
            height: 84,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 2000),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.neonGreen.withValues(alpha:0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonGreen.withValues(alpha: 0.05),
                    blurRadius: 20,
                  ),
                ],
              ),
            ).animate().scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1.1, 1.1),
                  duration: 1500.ms,
                  curve: Curves.easeInOut,
                ),
          ),
          // Shield icon
          Icon(
            Icons.shield_rounded,
            size: 48,
            color: AppColors.neonGreen,
          ),
        ],
      ),
    ).animate()
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.8, 0.8), duration: 500.ms);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.neonCyan, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surfaceVariant.withValues(alpha:0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonGreen, width: 2),
          gapPadding: 0,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.surfaceVariant.withValues(alpha:0.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha:0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.surfaceVariant.withValues(alpha:0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildAppleSignInButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha:0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.surfaceVariant.withValues(alpha:0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isLoading
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  try {
                    final service = ref.read(firebaseAuthProvider);
                    await service.signInWithApple();
                    if (mounted) {
                      navigator.pushReplacement(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    }
                  } catch (e) {
                    if (e.toString().contains('popup_closed')) {
                      // User cancelled
                    } else {
                      setState(() {
                        _errorMessage = 'Apple Sign-In failed. Try again.';
                      });
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Apple icon using SVG-style rendering
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CustomPaint(
                    painter: _AppleIconPainter(),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Sign in with Apple',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for Apple icon silhouette
class _AppleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.fill;

    // Simplified Apple icon using a path
    canvas.save();
    canvas.scale(size.width / 20, size.height / 24);

    // Apple body
    final path = Path();
    path.moveTo(10, 2);
    path.cubicTo(11.5, 1.5, 13, 2, 13, 2);
    path.cubicTo(13, 2, 14, 3, 14, 5);
    path.cubicTo(14, 5, 14, 7, 14, 7);
    path.cubicTo(14, 8, 12, 10, 10, 12);
    path.cubicTo(8, 10, 6, 8, 6, 5);
    path.cubicTo(6, 3, 8, 1.5, 10, 2);
    path.close();

    // Leaf
    final leaf = Path();
    leaf.moveTo(10, 2);
    leaf.cubicTo(9, 0, 11, -1, 12, 0);
    leaf.cubicTo(11, 1, 10, 1, 10, 2);
    leaf.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(leaf, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Background glow orb
class _GlowOrb extends StatelessWidget {
  final Color color;
  final double radius;

  const _GlowOrb({required this.color, required this.radius});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}
