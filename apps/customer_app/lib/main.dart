import 'package:flutter/material.dart';

void main() {
  runApp(const CustomerApp());
}

/// Stub entry point for the Customer Self-Ordering App.
///
/// This app has no path references to apps/staff_portal or the shared packages
/// at this stage (Req 1.3). It will be expanded in a subsequent phase.
class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'RMS Customer App',
      home: Scaffold(
        body: Center(child: Text('RMS Customer App — coming soon')),
      ),
    );
  }
}
