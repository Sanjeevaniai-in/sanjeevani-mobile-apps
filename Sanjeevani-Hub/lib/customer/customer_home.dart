import 'package:flutter/material.dart';
import 'customer_map_tab.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      body: CustomerMapTab(), // 🏠 Full-screen interactive 3D Map
    );
  }
}
