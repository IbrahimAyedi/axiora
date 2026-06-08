import 'package:flutter/material.dart';

import '../../../../core/widgets/section_card.dart';

class ImageQualityBanner extends StatelessWidget {
  const ImageQualityBanner({
    super.key,
    required this.label,
    required this.score,
  });

  final String label;
  final String score;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Image Labeling Preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          Text('Validation score: $score'),
        ],
      ),
    );
  }
}
