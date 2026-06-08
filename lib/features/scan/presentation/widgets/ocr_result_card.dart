import 'package:flutter/material.dart';

import '../../../../core/widgets/section_card.dart';

class OcrResultCard extends StatelessWidget {
  const OcrResultCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'OCR Result',
      child: Text(text),
    );
  }
}
