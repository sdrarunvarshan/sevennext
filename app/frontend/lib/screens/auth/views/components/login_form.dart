import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shop/route/guest_services.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/api_service.dart';
import '../../../../constants.dart';
import '../../../helpers/user_helper.dart';

class LogInForm extends StatefulWidget {
  const LogInForm({
    super.key,
    required this.formKey,
    required this.isB2C,
    this.onLoginSuccess,
  });

  final GlobalKey<FormState> formKey;
  final bool isB2C;
  final Function(String userType)? onLoginSuccess;

  @override
  State<LogInForm> createState() => _LogInFormState();
}

class _LogInFormState extends State<LogInForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!widget.formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Add user_type to the request body based on selected tab
      final response = await ApiService.post(
        '/auth/login',
        body: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'user_type': widget.isB2C ? 'b2c' : 'b2b', // Send user type in request
        },
      );

      final String? token = response['access_token'];
      final String? userTypeFromServer = response['user_type'];

      if (token == null || userTypeFromServer == null) {
        throw "Invalid login response";
      }

      // Check if the user is trying to login with wrong tab
      final expectedType = widget.isB2C ? 'b2c' : 'b2b';
      if (userTypeFromServer.toLowerCase() != expectedType) {
        throw "You are trying to login as ${widget.isB2C ? 'B2C' : 'B2B'} but your account is ${userTypeFromServer.toUpperCase()}";
      }

      // Save token and user type
      ApiService.token = token;
      final box = Hive.box('auth');
      await box.put('token', token);
      await box.put('is_guest', false);
      try {
        await box.put('user_email', _emailController.text.trim());
        print('LoginForm: Successfully saved user_email to Hive: ${_emailController.text.trim()}');
        // Verify immediately
        final savedEmail = await box.get('user_email');
        print('LoginForm: Verification - email in Hive after save: "$savedEmail"');
      } catch (e) {
        print('LoginForm: ERROR saving user_email to Hive: $e');
      }
      // Use UserHelper to save user type instead of auth box
      await UserHelper.setUserType(userTypeFromServer.toLowerCase());

      // Disable guest mode
      Provider.of<GuestService>(context, listen: false).setGuestMode(false);

      // Notify parent
      widget.onLoginSuccess?.call(userTypeFromServer.toLowerCase());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login successful!")),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          entryPointScreenRoute,
              (route) => false,
        );
      }
    } catch (e) {
      String message = e.toString();

      // Custom error messages
      if (message.contains("403")) {
        message = "B2B account pending approval or rejected.";
      } else if (message.contains("401")) {
        message = "Incorrect email or password";
      } else if (message.contains("You are trying to login")) {
        // Keep the custom error message for wrong user type
      } else {
        message = "Login failed. Please try again.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            validator: emaildValidator.call,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: "Email address",
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: defaultPadding),
          TextFormField(
            controller: _passwordController,
            validator: passwordValidator.call,
            obscureText: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: "Password",
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: defaultPadding),
          _isLoading
              ? CircularProgressIndicator(color: kPrimaryColor)
              : ElevatedButton(
            onPressed: _login,
            child: const Text("Log In"),
          ),
        ],
      ),
    );
  }
}