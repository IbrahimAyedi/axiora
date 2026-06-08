import 'package:flutter/material.dart';

import '../../../../core/widgets/section_card.dart';

class ResultSummaryCard extends StatelessWidget {
  const ResultSummaryCard({super.key, required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Summary',
      child: Text(summary),
    );
  }
}
