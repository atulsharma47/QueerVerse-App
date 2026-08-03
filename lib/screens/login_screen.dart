import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/auth_textfield.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  //==========================================================
  // Controllers
  //==========================================================

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  //==========================================================
  // Form State
  //==========================================================

  bool isLoading = false;
  bool rememberMe = false;

  //==========================================================
  // Animation
  //==========================================================

  late AnimationController _animationController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  //==========================================================
  // Init
  //==========================================================

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    slideAnimation =
        Tween<Offset>(begin: const Offset(0, .15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  //==========================================================
  // Dispose
  //==========================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  //==========================================================
  // Login
  //==========================================================

  Future<void> login() async {
    if (emailController.text.trim().isEmpty) {
      _showSnack("Please enter your email.");
      return;
    }

    if (passwordController.text.trim().isEmpty) {
      _showSnack("Please enter your password.");
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? "Login Failed");
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  //==========================================================
  // Forgot Password
  //==========================================================

  Future<void> _sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      if (!mounted) return;
      _showSnack("Password reset link sent to $email");
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? "Couldn't send reset email.");
    } catch (e) {
      _showSnack(e.toString());
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: emailController.text.trim(),
    );

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .6),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .25),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_reset_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
                const SizedBox(height: 14),
                const Text(
                  "Reset your password",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter your email and we'll send you a link to reset your password.",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: resetEmailController,
                  label: "Email",
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GradientButton(
                        text: "Send Link",
                        onPressed: () {
                          if (resetEmailController.text.trim().isEmpty) {
                            return;
                          }
                          Navigator.pop(dialogContext);
                          _sendPasswordReset(resetEmailController.text);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //==========================================================
  // Build
  //==========================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          //==================================================
          // Background Image
          //==================================================
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 1.08),
              duration: const Duration(seconds: 20),
              curve: Curves.easeInOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Image.asset(
                "assets/images/welcome_bg.png",
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),

          //==================================================
          // Dark Overlay
          //==================================================
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: .45)),
          ),

          //==================================================
          // Gradient Overlay
          //==================================================
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: .20),
                    AppColors.background.withValues(alpha: .92),
                  ],
                ),
              ),
            ),
          ),

          //==================================================
          // Main Content
          //==================================================
          SafeArea(
            child: Column(
              children: [
                //------------------------------------------------
                // Back Button
                //------------------------------------------------
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: FadeTransition(
                              opacity: fadeAnimation,
                              child: SlideTransition(
                                position: slideAnimation,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    //------------------------------------------------
                                    // Logo
                                    //------------------------------------------------
                                    const AppLogo(
                                      subtitle:
                                          "A universe where you can be you.",
                                    ),

                                    SizedBox(height: size.height * .025),

                                    //------------------------------------------------
                                    // Glass Card
                                    //------------------------------------------------
                                    GlassCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            "Welcome Back",
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),

                                          const SizedBox(height: 4),

                                          Text(
                                            "Sign in to continue your journey",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 14.5,
                                            ),
                                          ),

                                          const SizedBox(height: 18),

                                          //====================================
                                          // Form Fields
                                          //====================================
                                          _buildForm(),

                                          const SizedBox(height: 6),

                                          //====================================
                                          // Remember Me + Forgot Password
                                          //====================================
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    rememberMe = !rememberMe;
                                                  });
                                                },
                                                child: Row(
                                                  children: [
                                                    AnimatedContainer(
                                                      duration: const Duration(
                                                        milliseconds: 180,
                                                      ),
                                                      width: 18,
                                                      height: 18,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              5,
                                                            ),
                                                        border: Border.all(
                                                          color: rememberMe
                                                              ? AppColors
                                                                    .primary
                                                              : Colors.white
                                                                    .withValues(
                                                                      alpha: .4,
                                                                    ),
                                                          width: 1.4,
                                                        ),
                                                        gradient: rememberMe
                                                            ? LinearGradient(
                                                                colors: [
                                                                  AppColors
                                                                      .primary,
                                                                  AppColors
                                                                      .secondary,
                                                                ],
                                                              )
                                                            : null,
                                                      ),
                                                      child: rememberMe
                                                          ? const Icon(
                                                              Icons
                                                                  .check_rounded,
                                                              size: 14,
                                                              color:
                                                                  Colors.white,
                                                            )
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      "Remember Me",
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .textSecondary,
                                                        fontSize: 13.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    _showForgotPasswordDialog,
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: Size.zero,
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                                child: Text(
                                                  "Forgot Password?",
                                                  style: TextStyle(
                                                    color: AppColors.primary,
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 18),

                                          //====================================
                                          // Login Button
                                          //====================================
                                          _buildLoginButton(),

                                          const SizedBox(height: 20),

                                          //====================================
                                          // Divider
                                          //====================================
                                          _buildDivider(),

                                          const SizedBox(height: 16),

                                          //====================================
                                          // Social Buttons
                                          //====================================
                                          _buildSocialButtons(),

                                          const SizedBox(height: 16),

                                          _buildSignupLink(),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: size.height * .025),
                                  ],
                                ),
                              ),
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
        ],
      ),
    );
  }

  //==========================================================
  // Form
  //==========================================================

  Widget _buildForm() {
    return Column(
      children: [
        AuthTextField(
          controller: emailController,
          label: "Email",
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 16),

        AuthTextField(
          controller: passwordController,
          label: "Password",
          icon: Icons.lock_outline_rounded,
          isPassword: true,
        ),
      ],
    );
  }

  //==========================================================
  // Login Button
  //==========================================================

  Widget _buildLoginButton() {
    return GradientButton(
      text: "Login",
      isLoading: isLoading,
      onPressed: isLoading ? null : login,
    );
  }

  //==========================================================
  // Divider
  //==========================================================

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withValues(alpha: .12))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "OR",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: .12))),
      ],
    );
  }

  //==========================================================
  // Social Buttons
  //==========================================================
  //
  // NOTE: Replace with your real SocialButton widget once it's
  // available — wired up here as plain placeholders so the
  // layout matches the Signup screen until that widget exists.

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _socialPlaceholder("Google", Icons.g_mobiledata_rounded),
        ),
        const SizedBox(width: 14),
        Expanded(child: _socialPlaceholder("Apple", Icons.apple_rounded)),
      ],
    );
  }

  Widget _socialPlaceholder(String label, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.white.withValues(alpha: .15)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  //==========================================================
  // Bottom Signup Link
  //==========================================================

  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SignupScreen()),
            );
          },
          child: const Text(
            "Create Account",
            style: TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
