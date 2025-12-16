// lib/screens/auth/views/password_recovery_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/api_service.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/twilio_service.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isResetting = false;
  bool _phoneVerified = false;
  bool _showPassword = false;
  String? _verificationToken;

  // Step tracking: 1=Phone, 2=OTP, 3=New Password
  int _currentStep = 1;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSendingOtp = true);

    try {
      // Call backend to send OTP
      final response = await ApiService.post(
          '/auth/forgot-password/request',
          body: {'phone': _phoneController.text.trim()}
      );

      if (response['success'] == true) {
        setState(() => _currentStep = 2); // Move to OTP step

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to ${_phoneController.text}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to send OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter 6-digit OTP')),
      );
      return;
    }

    setState(() => _isVerifyingOtp = true);

    try {
      final response = await ApiService.post(
          '/auth/verify-reset-otp',
          body: {
            'phone': _phoneController.text.trim(),
            'otp': _otpController.text.trim()
          }
      );

      if (response['success'] == true) {
        _verificationToken = response['verification_token'];
        setState(() {
          _phoneVerified = true;
          _currentStep = 3; // Move to password reset step
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Phone verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Invalid OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isVerifyingOtp = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isResetting = true);

    try {
      final response = await ApiService.post(
          '/auth/reset-password',
          body: {
            'phone': _phoneController.text.trim(),
            'otp': _otpController.text.trim(),
            'new_password': _newPasswordController.text,
            'verification_token': _verificationToken,
          }
      );

      if (response['success'] == true) {
        // Clear any stored tokens (force re-login)
        final authBox = Hive.box('auth');
        await authBox.clear();
        ApiService.token = null;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password reset successful! Please login with new password'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back to login
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            logInScreenRoute,
                (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Reset failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isResetting = false);
    }
  }

  void _resendOtp() async {
    setState(() => _isSendingOtp = true);

    try {
      final response = await ApiService.post(
          '/auth/resend-reset-otp',
          body: {'phone': _phoneController.text.trim()}
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New OTP sent to ${_phoneController.text}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resend: $e')),
      );
    } finally {
      setState(() => _isSendingOtp = false);
    }
  }

  void _goBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        title: const Text('Reset Password'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: SvgPicture.asset(
                    "assets/logo/Shoplon.svg",
                    height: 80,
                  ),
                ),
                const SizedBox(height: defaultPadding),
                Text(
                  'Reset Password',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: defaultPadding / 2),
                const Text(
                  'Enter your registered phone number to reset password',
                ),
                const SizedBox(height: defaultPadding),

                // Step Indicator
                _buildStepIndicator(),
                const SizedBox(height: defaultPadding),

                // Step 1: Phone Input
                if (_currentStep == 1) _buildPhoneStep(),

                // Step 2: OTP Verification
                if (_currentStep == 2) _buildOtpStep(),

                // Step 3: New Password
                if (_currentStep == 3) _buildPasswordStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStepCircle(1, 'Phone', _currentStep >= 1),
        Container(
          height: 2,
          width: 40,
          color: _currentStep >= 2 ? kPrimaryColor : Colors.grey.shade300,
        ),
        _buildStepCircle(2, 'Verify', _currentStep >= 2),
        Container(
          height: 2,
          width: 40,
          color: _currentStep >= 3 ? kPrimaryColor : Colors.grey.shade300,
        ),
        _buildStepCircle(3, 'Reset', _currentStep >= 3),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: active ? kPrimaryColor : Colors.grey.shade300,
          child: Text(
            '$step',
            style: TextStyle(
              color: active ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? kPrimaryColor : Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      children: [
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Phone number required';
            }
            if (!RegExp(r'^\+?[0-9]{10,13}$').hasMatch(value)) {
              return 'Enter valid phone number';
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Registered phone number',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: defaultPadding),
        const Text(
          'We will send a verification code to this number',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: defaultPadding),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSendingOtp ? null : _sendOtp,
            child: _isSendingOtp
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text('Send Verification Code'),
          ),
        ),
        const SizedBox(height: defaultPadding),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to Login'),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        // Phone display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.phone, color: kPrimaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                _phoneController.text,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: _currentStep == 1 ? null : () => setState(() => _currentStep = 1),
                child: const Text('Change'),
              ),
            ],
          ),
        ),
        const SizedBox(height: defaultPadding),
        // OTP Input
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Enter 6-digit code',
            prefixIcon: const Icon(Icons.lock_clock),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            counterText: '',
          ),
        ),
        const SizedBox(height: 8),
        // Resend OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _isSendingOtp ? null : _resendOtp,
              child: _isSendingOtp
                  ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Resend Code'),
            ),
          ],
        ),
        const SizedBox(height: defaultPadding),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isVerifyingOtp ? null : _verifyOtp,
            child: _isVerifyingOtp
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text('Verify Code'),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        // Success indicator
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.verified, color: Colors.green.shade700),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Phone verified successfully',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: defaultPadding),
        // New Password
        TextFormField(
          controller: _newPasswordController,
          obscureText: !_showPassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Enter new password';
            }
            if (value.length < 6) {
              return 'Minimum 6 characters';
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'New password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: defaultPadding),
        // Confirm Password
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_showPassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Confirm your password';
            }
            if (value != _newPasswordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Confirm new password',
            prefixIcon: const Icon(Icons.lock_reset),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: defaultPadding),
        // Password requirements
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Password must have:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              SizedBox(height: 4),
              Text(
                '• At least 6 characters\n• Not too common\n• Not similar to phone number',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: defaultPadding),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isResetting ? null : _resetPassword,
            child: _isResetting
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text('Reset Password'),
          ),
        ),
      ],
    );
  }
}