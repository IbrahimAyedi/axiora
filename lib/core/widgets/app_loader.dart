import 'package:flutter/material.dart';

// widget reusable mte3 loading
class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) {
    // nwarriw loading indicator fi west screen
    return const Center(child: CircularProgressIndicator());
  }
}
