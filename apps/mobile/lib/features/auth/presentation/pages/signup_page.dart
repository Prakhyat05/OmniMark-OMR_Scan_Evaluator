import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/navigation_utils.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _orgNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Institute account registered successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safePop('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Register Institute',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set up your school, college, or coaching center workspace.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),

                // Full Name
                Text('Your Full Name *', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Dr. Rajesh Sharma',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.outline),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Full name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Organization Name
                Text('Institute / Organization Name *', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _orgNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Apex International Academy',
                    prefixIcon: Icon(Icons.apartment_rounded, color: AppColors.outline),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Institute name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Official Email
                Text('Official Email Address *', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'admin@apexacademy.edu',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.outline),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Email address is required';
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(val.trim())) return 'Please enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                Text('Create Password *', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Minimum 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.outline,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Password is required';
                    if (val.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
