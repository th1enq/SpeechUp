import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_profile.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        final credential = await _authService.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );

        // Create user profile in Firestore
        if (credential.user != null) {
          final profile = UserProfile(
            uid: credential.user!.uid,
            displayName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            createdAt: DateTime.now(),
          );
          await _firestoreService.createUserProfile(profile);
        }
      }
      widget.onLoginSuccess();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();

    return Scaffold(
      backgroundColor: AppColors.onboardingBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Logo
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.onboardingBlueDeep,
                        AppColors.onboardingBlue,
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.graphic_eq_rounded,
                        color: Colors.white.withValues(alpha: 0.35),
                        size: 40,
                      ),
                      const Icon(
                        Icons.mic_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'SpeechUp',
                textAlign: TextAlign.center,
                style: base.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onboardingNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? 'Đăng nhập để tiếp tục luyện tập'
                    : 'Tạo tài khoản mới',
                textAlign: TextAlign.center,
                style: base.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onboardingTextMuted,
                ),
              ),
              const SizedBox(height: 36),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name field (register only)
                    if (!_isLogin) ...[
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Họ và tên',
                        icon: Icons.person_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Email
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!value.contains('@')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Password
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Mật khẩu',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.onboardingTextMuted,
                          size: 22,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (value.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Error message
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: base.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Submit button
              SizedBox(
                height: 54,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _submit,
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: _isLoading
                            ? null
                            : AppColors.onboardingCtaGradient,
                        color: _isLoading
                            ? AppColors.onboardingDotInactive
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isLoading
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.onboardingBlue.withValues(
                                    alpha: 0.28,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                _isLogin ? 'Đăng nhập' : 'Đăng ký',
                                style: base.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Toggle login/register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? 'Chưa có tài khoản? ' : 'Đã có tài khoản? ',
                    style: base.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onboardingTextMuted,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _isLogin ? 'Đăng ký' : 'Đăng nhập',
                      style: base.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onboardingBlue,
                      ),
                    ),
                  ),
                ],
              ),

              // Forgot password (login only)
              if (_isLogin) ...[
                const SizedBox(height: 14),
                Center(
                  child: GestureDetector(
                    onTap: () => _showForgotPassword(context),
                    child: Text(
                      'Quên mật khẩu?',
                      style: base.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onboardingTextMuted,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.onboardingTextMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final base = GoogleFonts.plusJakartaSans();
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.onboardingNavy,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: base.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.onboardingTextMuted,
        ),
        prefixIcon: Icon(icon, color: AppColors.onboardingTextMuted, size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.onboardingDotInactive.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.onboardingDotInactive.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.onboardingBlue,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  void _showForgotPassword(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    final resetEmailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onboardingDotInactive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Đặt lại mật khẩu',
              style: base.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onboardingNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhập email để nhận liên kết đặt lại mật khẩu',
              textAlign: TextAlign.center,
              style: base.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.onboardingTextMuted,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: resetEmailController,
              hint: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    if (resetEmailController.text.trim().isNotEmpty) {
                      try {
                        await _authService.resetPassword(
                          resetEmailController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Đã gửi email đặt lại mật khẩu!',
                                style: base.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: AppColors.feedbackGood,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: AppColors.onboardingCtaGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'Gửi email',
                        style: base.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
