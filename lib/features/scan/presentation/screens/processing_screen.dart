import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appSessionProvider.notifier).markActiveScanProcessing();
    });

    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      ref.read(appSessionProvider.notifier).completeActiveScan();
      context.pushReplacement(RouteNames.resultPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeScan = ref.watch(appSessionProvider).activeScan;

    return AppPageScaffold(
      title: 'Processing',
      subtitle: 'Step 3 of 4',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE7F0FB),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD7E0EA)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF124170),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Analyzing your capture',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                activeScan == null
                    ? 'Starting OCR, validation, and profile extraction...'
                    : 'Running ${activeScan.status.value} flow for ${activeScan.scanType.value}...',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF5C6773),
                ),
              ),
              const SizedBox(height: 32),
              const _ProcessingSteps(),
              const SizedBox(height: 40),
              AppButton(
                label: 'Cancel',
                variant: AppButtonVariant.secondary,
                icon: Icons.close_rounded,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcessingSteps extends StatelessWidget {
  const _ProcessingSteps();

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.image_search_outlined, 'Image validation', true),
      (Icons.text_fields_outlined, 'OCR extraction', true),
      (Icons.summarize_outlined, 'Summary generation', false),
    ];

    return Column(
      children: steps.map((step) {
        final (icon, label, done) = step;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: done
                      ? const Color(0xFFE7F0FB)
                      : const Color(0xFFF3F6FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  done ? Icons.check_rounded : icon,
                  size: 16,
                  color: done
                      ? const Color(0xFF124170)
                      : const Color(0xFF5C6773).withAlpha(140),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: done
                      ? const Color(0xFF18212F)
                      : const Color(0xFF5C6773).withAlpha(160),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
