import 'package:flutter/material.dart';

import '../../../../app/config/app_constants.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';

// screen mte3 about
// ywarri overview 3al application, services, features w version
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      // title mte3 page
      title: 'About',

      // subtitle mte3 page
      subtitle: 'Application overview',

      // contenu principal mte3 page
      body: Column(
        children: [
          // section mte3 application overview
          SectionCard(
            title: AppConstants.appName,
            subtitle: 'Axiora / Smart Constat',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // description courte mte3 app
                Text(
                  'A Flutter mobile application for intelligent car accident reporting.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                // description detaillee mte3 app
                const Text(
                  'Smart Constat helps users create digital constats by scanning documents, extracting data, analyzing accident descriptions, analyzing vehicle damage photos, and saving reports.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // section mte3 ML Kit services
          SectionCard(
            title: 'ML Kit Services',
            subtitle: 'Official Google ML Kit integrations',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // feature mte3 text recognition
                _FeatureHeader(
                  icon: Icons.document_scanner,
                  title: '1. ML Kit Text Recognition',
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),

                // documents eli OCR ykhdem 3lihom
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Used for OCR on official documents:'),
                      SizedBox(height: 4),
                      Text('• Driving license (Permis)'),
                      Text('• Vehicle registration (Carte grise)'),
                      Text('• Insurance attestation (Assurance)'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // feature mte3 entity extraction
                _FeatureHeader(
                  icon: Icons.auto_awesome,
                  title: '2. ML Kit Entity Extraction',
                  color: Colors.purple,
                ),
                const SizedBox(height: 8),

                // entities eli service yest5arjhom
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Used to analyze accident descriptions and extract structured information:',
                      ),
                      SizedBox(height: 4),
                      Text('• Dates'),
                      Text('• Phone numbers'),
                      Text('• Addresses/locations'),
                      Text('• Other useful entities'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // section mte3 custom AI feature
          SectionCard(
            title: 'Custom AI Feature',
            subtitle: 'Additional AI beyond ML Kit',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // feature mte3 damage detection
                _FeatureHeader(
                  icon: Icons.car_crash,
                  title: 'Vehicle Damage Detection',
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),

                // description mte3 damage detection
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Custom vehicle damage detection model/API used to analyze damage photos and add damage summaries to constats.',
                      ),
                      SizedBox(height: 4),
                      Text(
                        'This is an additional AI feature beyond the required ML Kit services.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // section mte3 Firebase services
          SectionCard(
            title: 'Firebase Services',
            subtitle: 'Backend infrastructure',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Firebase Auth lel login/register
                _ServiceRow(
                  icon: Icons.lock,
                  title: 'Firebase Auth',
                  description: 'User authentication (login/register)',
                ),
                const SizedBox(height: 12),

                // Firestore lel data storage
                _ServiceRow(
                  icon: Icons.cloud,
                  title: 'Cloud Firestore',
                  description:
                      'User profiles, drafts, constats, and history storage',
                ),
                const SizedBox(height: 12),

                // Firebase Storage lel photos
                _ServiceRow(
                  icon: Icons.photo_library,
                  title: 'Firebase Storage',
                  description: 'Damage photo storage',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // section mte3 main features
          SectionCard(
            title: 'Main Features',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FeatureItem('Document OCR autofill'),
                _FeatureItem('Smart accident notes'),
                _FeatureItem('Damage photo analysis'),
                _FeatureItem('Drafts and history'),
                _FeatureItem('Review and submit constat'),
                _FeatureItem('Firestore persistence'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // section mte3 version info
          SectionCard(
            title: 'Version',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // version mte3 app
                Text(
                  'Version 1.0.0+1',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),

                // framework mte3 app
                Text(
                  'Built with Flutter',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// widget sghir ywarri header mte3 feature b icon w title
class _FeatureHeader extends StatelessWidget {
  const _FeatureHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  // icon mte3 feature
  final IconData icon;

  // title mte3 feature
  final String title;

  // couleur mte3 icon background
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ncheckiw theme dark wala light
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        // icon container
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),

        // feature title
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// widget sghir ywarri service row b icon, title w description
class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  // icon mte3 service
  final IconData icon;

  // title mte3 service
  final String title;

  // description mte3 service
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // service icon
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),

        // title w description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // service title
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),

              // service description
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// widget sghir ywarri feature item b check icon
class _FeatureItem extends StatelessWidget {
  const _FeatureItem(this.text);

  // text mte3 feature
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ncheckiw theme dark wala light
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // check icon
          Icon(
            Icons.check_circle,
            size: 16,
            color: isDark ? Colors.green.shade400 : Colors.green.shade600,
          ),
          const SizedBox(width: 8),

          // feature text
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
