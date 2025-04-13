import 'package:flutter/material.dart';
import 'package:recap_today/widget/background.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('하루 요약', style: textTheme.headlineMedium),
        centerTitle: true,
      ),
      body: Container(
        decoration: commonTabDecoration(),
      ),
    );
  }
}