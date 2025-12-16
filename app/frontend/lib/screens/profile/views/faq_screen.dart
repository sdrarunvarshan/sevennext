import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {"question": "What is this app?", "answer": "This is a sample FAQ app for an electronics company."},
      {"question": "How do I use it?", "answer": "Simply browse through the FAQs to find answers to your questions."},
      {"question": "Where can I get help?", "answer": "Contact support at sevenxt2023@gmail.com for assistance."}
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('FAQs')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return _buildFAQ(
            question: faqs[index]['question']!,
            answer: faqs[index]['answer']!,
            context: context,
          );
        },
      ),
    );
  }

  Widget _buildFAQ({
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