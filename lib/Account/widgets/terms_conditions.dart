import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class TermsAndConditions extends StatefulWidget {
  const TermsAndConditions({super.key});

  @override
  State<TermsAndConditions> createState() =>
      _TermsAndConditionsState();
}

class _TermsAndConditionsState extends State<TermsAndConditions> {
  String _termsText = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    final terms = await rootBundle.loadString(
      'assets/terms_conditions.txt',
    );
    setState(() {
      _termsText = terms;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms and Conditions"),
        backgroundColor: Colors.cyan,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(_termsText, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
