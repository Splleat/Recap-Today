import 'package:flutter/material.dart';
import 'package:recap_today/widget/background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  Widget build(BuildContext context) {

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          }
        )
      ),
      body: Container(
        decoration: commonTabDecoration(),
      ),
    );
  }
}