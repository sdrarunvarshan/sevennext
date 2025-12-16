import 'package:flutter/material.dart';
import 'package:shop/constants.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final helpSections = [
      {
        "category": "Getting Started",
        "items": [
          {
            "question": "What is Sevenxt2023?",
            "answer": "Sevenxt2023 is a B2C and B2B e-commerce platform offering competitive pricing and seamless shopping experiences for both individual consumers and business partners."
          },
          {
            "question": "How do I register?",
            "answer": "Visit the registration page and select your user type (B2C or B2B). Fill in your details and submit. B2C users can access the app immediately after registration. B2B users must wait for admin approval before accessing the platform."
          },
        ]
      },
      {
        "category": "B2C Users",
        "items": [
          {
            "question": "How do I get started as a B2C user?",
            "answer": "Register with your details on the app. Once registration is complete, you can immediately start browsing and purchasing products. Your pricing is based on B2C rates."
          },
          {
            "question": "Can I browse products before logging in?",
            "answer": "You need to register and log in to access the full app features and make purchases."
          },
        ]
      },
      {
        "category": "B2B Users",
        "items": [
          {
            "question": "How do I register as a B2B user?",
            "answer": "Select 'B2B' during registration and provide your business details. After submission, your profile will be reviewed by our admin team for approval."
          },
          {
            "question": "Why can't I log in after logging out?",
            "answer": "B2B users require admin approval after registration and each logout. Once you log out, you cannot log back in until the admin approves your profile. This ensures security and verification of business accounts."
          },
          {
            "question": "What are the B2B pricing differences?",
            "answer": "B2B users receive special wholesale pricing based on bulk orders and business agreements. Pricing is displayed differently in your account compared to B2C users. Contact our sales team for custom quotes."
          },
          {
            "question": "How long does admin approval take?",
            "answer": "Admin approval typically takes 24-48 business hours. You'll receive a notification once your profile is approved and you can log in again."
          },
        ]
      },
      {
        "category": "Pricing & Billing",
        "items": [
          {
            "question": "Why are prices different for B2B and B2C?",
            "answer": "B2B users receive wholesale pricing based on bulk purchasing and business partnerships. B2C users see standard retail pricing. Pricing is automatically adjusted based on your user type."
          },
          {
            "question": "How are prices displayed in my account?",
            "answer": "Prices are displayed based on your user type. Log in to view pricing specific to your account category (B2C or B2B)."
          },
        ]
      },
      {
        "category": "Account & Security",
        "items": [
          {
            "question": "How do I change my password?",
            "answer": "To change your password, please send an email to sevenxt2023@gmail.com with your request. Our support team will assist you with the password change process."
          },
          {
            "question": "What should I do if I forget my password?",
            "answer": "Contact our support team at sevenxt2023@gmail.com. Provide your registered email or business details, and we'll help you reset your password securely."
          },
          {
            "question": "Is my data secure?",
            "answer": "Yes, we use industry-standard encryption and security protocols to protect your personal and business information."
          },
        ]
      },
      {
        "category": "Support & Contact",
        "items": [
          {
            "question": "How do I contact support?",
            "answer": "Email us at sevenxt2023@gmail.com for any assistance. Our support team is available to help with account issues, password changes, and general inquiries."
          },
          {
            "question": "What are your support hours?",
            "answer": "Our support team typically responds to emails within 24 business hours. For urgent matters, please mention 'URGENT' in your email subject."
          },
        ]
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
       ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: helpSections.length,
        itemBuilder: (context, index) {
          final section = helpSections[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  section["category"] as String,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor, // Use kPrimaryColor for category title color
                  ),
                ),
              ),
              ...List.generate(
                (section["items"] as List).length,
                    (i) {
                  final item = (section["items"] as List)[i];
                  return _buildHelpItem(
                    question: item["question"] as String,
                    answer: item["answer"] as String,
                    context: context,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHelpItem({
    required String question,
    required String answer,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ExpansionTile(
        title: Text(
          question,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}