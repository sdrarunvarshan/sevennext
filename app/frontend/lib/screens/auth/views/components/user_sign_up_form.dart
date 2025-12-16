import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart'; // Added
import 'package:shop/route/api_service.dart';
import 'package:shop/route/guest_services.dart'; // Added
import 'package:shop/screens/auth/views/components/otp_dialog.dart';

import '../../../../constants.dart';
import '../../../../route/route_constants.dart';
import '../../../../route/twilio_service.dart';
import '../../../helpers/user_helper.dart';

class UserSignUpForm extends StatefulWidget {
  const UserSignUpForm({
    super.key,
    required this.formKey,
    required this.agreeToTerms,
  });

  final GlobalKey<FormState> formKey;
  final bool agreeToTerms;

  @override
  State<UserSignUpForm> createState() => _UserSignUpFormState();
}

class _UserSignUpFormState extends State<UserSignUpForm> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _addressController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _addressController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _agreeToTerms = widget.agreeToTerms;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // In UserSignUpForm - update the _signUp method
  Future<void> _verifyAndSignUp() async {
    if (!widget.formKey.currentState!.validate()) return;

    final rawPhone = _phoneNumberController.text.trim();

    String phoneNumber;

    // 1️⃣ Validate & format phone number
    try {
      if (!TwilioService.isValidPhoneNumber(rawPhone)) {
        throw Exception("Invalid phone number");
      }
      phoneNumber = TwilioService.formatPhoneNumber(rawPhone);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter a valid Indian phone number")),
        );
      }
      return;
    }

    print("📱 Sending OTP for phone: $phoneNumber");

    // 2️⃣ Send OTP
    final otpResult = await TwilioService.sendVerificationOtp(phoneNumber);
    if (otpResult['success'] != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(otpResult['message'] ?? "Failed to send OTP"),
          ),
        );
      }
      return;
    }

    // 3️⃣ Show OTP dialog
    String? otp = await showDialog<String>(
      context: context,
      builder: (context) => OtpDialog(phone: phoneNumber),
    );

    if (otp == null || otp.isEmpty) return;
    print("📱 User entered OTP: $otp");

    // 4️⃣ Verify OTP
    final verifyResult = await TwilioService.verifyOtp(phoneNumber, otp);
    print(
        "📱 Verify OTP Result: ${verifyResult['success']} - ${verifyResult['message']}");

    if (verifyResult['success'] != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(verifyResult['message'] ?? "Invalid OTP"),
          ),
        );
      }
      return;
    }

    print("✅ OTP verified, proceeding with signup...");

    // 5️⃣ Proceed with signup
    await _signUp();
  }

  Future<void> _signUp() async {
      if (!widget.formKey.currentState!.validate()) return;

      final fullName = _fullNameController.text.trim();
      final phoneNumber = _phoneNumberController.text.trim();
      final addressInput = _addressController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      String street = '';
      String city = '';
      String postalCode = '';
      String country = '';
      final bool addressProvided = addressInput.isNotEmpty;

      if (addressProvided) {
        final parts = addressInput.split(',').map((e) => e.trim()).toList();
        street = parts.isNotEmpty ? parts[0] : '';
        city = parts.length > 1 ? parts[1] : '';
        postalCode = parts.length > 2 ? parts[2] : '';
        country = parts.length > 3 ? parts[3] : '';
      }

      // Create the request body for B2C signup
      final Map<String, dynamic> body = {
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'address': addressProvided ? {
          'street': street,
          'city': city,
          'postal_code': postalCode,
          'country': country,
          'name': 'Primary Address',
          'is_default': true,
        } : null,
      };

      try {
        // Send data to the backend API
        final response = await ApiService.post(
          '/auth/register/b2c',
          body: body,
        );

        if (!mounted) return;

        // Store token in ApiService and Hive
        final accessToken = response['access_token'] as String?;
        if (accessToken != null) {
          ApiService.token = accessToken;
          final authBox = Hive.box('auth');

          // IMPORTANT: Save token BEFORE making any other API calls
          await authBox.put('token', accessToken);
          await authBox.put('is_guest', false);

          // Save user data
          await authBox.put('user_name', fullName);
          await authBox.put('user_email', email);
          await authBox.put('user_phone', phoneNumber);

          print('✅ B2C Signup: Saved token and user data to Hive');
          print('  - Token: ${accessToken.substring(0, 20)}...');
          print('  - Name: $fullName');
          print('  - Email: $email');
          print('  - Phone: $phoneNumber');

          // Verify token is set in ApiService
          print('✅ ApiService.token is now: ${ApiService.token?.substring(
              0, 20)}...');

          // Disable guest mode
          Provider.of<GuestService>(context, listen: false).setGuestMode(false);
          await UserHelper.setUserType(UserHelper.b2c);
          print('✅ B2C Signup: Set user type to B2C');
        }

        // Handle success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Sign up successful!'),
          ),
        );

        // Navigate after all async work is done
        Navigator.pushNamedAndRemoveUntil(
            context, entryPointScreenRoute, (r) => false);
      } catch (e) {
        if (!mounted) return;

        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign Up Failed: $e'),
            backgroundColor: Theme
                .of(context)
                .colorScheme
                .error,
          ),
        );
      }
    }
    @override
    Widget build(BuildContext context) {
      return Form(
        key: widget.formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _fullNameController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.name,
              decoration: InputDecoration(
                hintText: 'Full Name',
                prefixIcon: Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: defaultPadding * 0.75),
                  child: SvgPicture.asset(
                    'assets/icons/Profile.svg',
                    height: 24,
                    width: 24,
                    colorFilter: ColorFilter.mode(
                      Theme
                          .of(context)
                          .textTheme
                          .bodyLarge!
                          .color!
                          .withOpacity(0.3),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: defaultPadding),
            TextFormField(
              controller: _phoneNumberController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Phone Number',
                prefixIcon: Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: defaultPadding * 0.75),
                  child: SvgPicture.asset(
                    'assets/icons/Call.svg',
                    height: 24,
                    width: 24,
                    colorFilter: ColorFilter.mode(
                      Theme
                          .of(context)
                          .textTheme
                          .bodyLarge!
                          .color!
                          .withOpacity(0.3),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: defaultPadding),
            TextFormField(
              controller: _addressController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.streetAddress,
              decoration: InputDecoration(
                hintText: 'Address (Street, City, Postal Code, Country)',
                prefixIcon: Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: defaultPadding * 0.75),
                  child: SvgPicture.asset(
                    'assets/icons/Address.svg',
                    height: 24,
                    width: 24,
                    colorFilter: ColorFilter.mode(
                      Theme
                          .of(context)
                          .textTheme
                          .bodyLarge!
                          .color!
                          .withOpacity(0.3),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: defaultPadding),
            TextFormField(
              controller: _emailController,
              validator: emaildValidator.call,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email address',
                prefixIcon: Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: defaultPadding * 0.75),
                  child: SvgPicture.asset(
                    'assets/icons/Message.svg',
                    height: 24,
                    width: 24,
                    colorFilter: ColorFilter.mode(
                      Theme
                          .of(context)
                          .textTheme
                          .bodyLarge!
                          .color!
                          .withOpacity(0.3),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: defaultPadding),
            TextFormField(
              controller: _passwordController,
              validator: passwordValidator.call,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: defaultPadding * 0.75),
                  child: SvgPicture.asset(
                    'assets/icons/Lock.svg',
                    height: 24,
                    width: 24,
                    colorFilter: ColorFilter.mode(
                      Theme
                          .of(context)
                          .textTheme
                          .bodyLarge!
                          .color!
                          .withOpacity(0.3),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: defaultPadding),
            Row(
              children: [
                Checkbox(
                  activeColor: kPrimaryColor,
                  onChanged: (value) {
                    setState(() {
                      _agreeToTerms = value!;
                    });
                  },
                  value: _agreeToTerms,
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: "I agree with the",
                      children: [
                        TextSpan(
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(
                                  context, termsOfServicesScreenRoute);
                            },
                          text: " Terms of service ",
                          style: const TextStyle(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const TextSpan(
                          text: "& privacy policy.",
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: defaultPadding),
            ElevatedButton(
              onPressed: _agreeToTerms ? _verifyAndSignUp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                // Static Red Background
                foregroundColor: Colors.white,
                // Static White Text
                minimumSize: const Size(double.infinity, 50),
                // Explicitly set text color for disabled state to white to prevent grey color change
                disabledBackgroundColor: kPrimaryColor,
                disabledForegroundColor: Colors.white.withOpacity(
                    0.5), // Slightly faded white text when disabled
              ),
              child: const Text('Sign Up'),
            ),
          ],
        ),
      );
    }
  }
