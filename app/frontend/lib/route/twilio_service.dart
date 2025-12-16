import 'dart:convert';
import 'package:http/http.dart' as http;

class TwilioService {
  static const String _baseUrl = "http://127.0.0.1:8000";

  // Send OTP for registration (B2C/B2B) - UPDATED
  static Future<Map<String, dynamic>> sendVerificationOtp(String phoneNumber) async {
    try {
      String formattedPhone = formatPhoneNumber(phoneNumber);

      final response = await http.post(
          Uri.parse("$_baseUrl/auth/send-verification"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "phone": formattedPhone,  // Only send phone, not purpose
          })
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "success": true,
          "message": data['message'] ?? "OTP sent successfully",
          "sid": data['sid'],
          "data": data
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          "success": false,
          "message": errorData['detail'] ?? "Failed to send OTP",
          "status_code": response.statusCode
        };
      }
    } catch (e) {
      print("Error sending OTP: $e");
      return {
        "success": false,
        "message": "Network error: $e"
      };
    }
  }

  // Verify OTP for registration - NO CHANGES
  static Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    try {
      final response = await http.post(
          Uri.parse("$_baseUrl/auth/verify-otp"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "phone": phoneNumber,
            "otp": otp
          })
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "success": true,
          "message": data['message'] ?? "Phone verified successfully",
          "data": data
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          "success": false,
          "message": errorData['detail'] ?? "Invalid OTP",
          "status_code": response.statusCode
        };
      }
    } catch (e) {
      print("Error verifying OTP: $e");
      return {
        "success": false,
        "message": "Verification failed: $e"
      };
    }
  }

  // Request password reset OTP - NO CHANGES
  static Future<Map<String, dynamic>> requestPasswordReset(String phoneNumber) async {
    try {
      final response = await http.post(
          Uri.parse("$_baseUrl/auth/forgot-password/request"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"phone": phoneNumber})
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "success": true,
          "message": data['message'] ?? "Reset OTP sent",
          "sid": data['sid'],
          "data": data
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          "success": false,
          "message": errorData['detail'] ?? "Failed to send reset OTP",
          "status_code": response.statusCode
        };
      }
    } catch (e) {
      print("Error requesting password reset: $e");
      return {
        "success": false,
        "message": "Reset request failed: $e"
      };
    }
  }

  // Reset password - NO CHANGES
  static Future<Map<String, dynamic>> resetPassword(String phoneNumber, String otp, String newPassword) async {
    try {
      final response = await http.post(
          Uri.parse("$_baseUrl/auth/reset-password"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "phone": phoneNumber,
            "otp": otp,
            "new_password": newPassword
          })
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "success": true,
          "message": data['message'] ?? "Password reset successful",
          "data": data
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          "success": false,
          "message": errorData['detail'] ?? "Password reset failed",
          "status_code": response.statusCode
        };
      }
    } catch (e) {
      print("Password reset error: $e");
      return {
        "success": false,
        "message": "Password reset error: $e"
      };
    }
  }

  // Remove these methods since they don't exist in your FastAPI:
  // - sendB2bVerificationOtp
  // - verifyB2bOtp
  // - verifyResetOtp
  // - resendOtp

  // Add this helper method for phone validation
  static String formatPhoneNumber(String phone) {
    // Remove any non-digit characters
    String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Ensure it starts with +91 for Indian numbers if not already formatted
    if (digits.length == 10) {
      return '+91$digits';
    } else if (digits.length == 12 && digits.startsWith('91')) {
      return '+$digits';
    } else if (!phone.startsWith('+')) {
      return '+$digits';
    }
    return phone;
  }

  // Simple phone validation
  static bool isValidPhoneNumber(String phone) {
    // Remove any non-digit characters
    String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    // Check if it's 10 digits (Indian mobile) or 12 digits (with 91 country code)
    return digits.length == 10 || (digits.length == 12 && digits.startsWith('91'));
  }
}