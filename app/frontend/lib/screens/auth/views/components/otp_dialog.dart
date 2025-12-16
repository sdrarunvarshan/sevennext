import 'package:flutter/material.dart';
class OtpDialog extends StatefulWidget {
  final String phone;

  const OtpDialog({super.key, required this.phone});

  @override
  _OtpDialogState createState() => _OtpDialogState();
}

class _OtpDialogState extends State<OtpDialog> {
  final TextEditingController _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Verify Phone"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Enter OTP sent to ${widget.phone}"),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: "6-digit OTP"),
          )
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel")
        ),
        ElevatedButton(
            onPressed: () => Navigator.pop(context, _otpController.text),
            child: Text("Verify")
        )
      ],
    );
  }
}