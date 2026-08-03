import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/auth_textfield.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

import 'home_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  //==========================================================
  // Controllers
  //==========================================================

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  //==========================================================
  // Form State
  //==========================================================

  bool isLoading = false;

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
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  //==========================================================
  // Signup
  //==========================================================

  Future<void> signUp() async {
    if (fullNameController.text.trim().isEmpty) {
      _showSnack("Please enter your full name.");
      return;
    }

    if (emailController.text.trim().isEmpty) {
      _showSnack("Please enter your email.");
      return;
    }

    if (passwordController.text.trim().length < 6) {
      _showSnack("Password must be at least 6 characters.");
      return;
    }

    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      _showSnack("Passwords do not match.");
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final uid = credential.user!.uid;

      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "uid": uid,
        "email": emailController.text.trim(),
        "fullName": fullNameController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? "Signup Failed");
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
                                            "Create Account",
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
                                            "Let's get you started",
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

                                          //====================================
                                          // Forgot Password
                                          //====================================
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed:
                                                  _showForgotPasswordDialog,
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
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
                                          ),

                                          const SizedBox(height: 12),

                                          //====================================
                                          // Signup Button
                                          //====================================
                                          _buildSignupButton(),

                                          const SizedBox(height: 16),

                                          _buildLoginLink(),
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
          controller: fullNameController,
          label: "Full Name",
          icon: Icons.person_outline_rounded,
        ),

        const SizedBox(height: 16),

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

        const SizedBox(height: 16),

        AuthTextField(
          controller: confirmPasswordController,
          label: "Confirm Password",
          icon: Icons.lock_outline_rounded,
          isPassword: true,
        ),
      ],
    );
  }

  //==========================================================
  // Signup Button
  //==========================================================

  Widget _buildSignupButton() {
    return GradientButton(
      text: "Create Account",
      isLoading: isLoading,
      onPressed: isLoading ? null : signUp,
    );
  }

  //==========================================================
  // Bottom Login Link
  //==========================================================

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          child: const Text(
            "Log In",
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
