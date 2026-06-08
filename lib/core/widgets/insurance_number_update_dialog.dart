import 'package:flutter/material.dart';

import 'app_button.dart';

/// Dialog to confirm updating user profile insurance number
// dialog yets2el user ken yheb ysave wala yupdate insurance number
class InsuranceNumberUpdateDialog extends StatelessWidget {
  const InsuranceNumberUpdateDialog({
    required this.currentInsuranceNumber,
    required this.scannedInsuranceNumber,
    super.key,
  });

  // insurance number eli deja mawjoud fi profile
  final String? currentInsuranceNumber;

  // insurance number eli tscanneh mel document
  final String scannedInsuranceNumber;

  @override
  Widget build(BuildContext context) {
    // theme mte3 app
    final theme = Theme.of(context);

    // true ken user deja 3andou insurance number fi profile
    final hasCurrentNumber =
        currentInsuranceNumber != null && currentInsuranceNumber!.isNotEmpty;

    return AlertDialog(
      // title yetbadel 7asb fama current number wala le
      title: Text(
        hasCurrentNumber
            ? 'Update profile insurance number?'
            : 'Save insurance number to your profile?',
        style: theme.textTheme.titleLarge,
      ),

      // contenu mte3 dialog
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ken fama current number, nwarriwh lel user
          if (hasCurrentNumber) ...[
            Text(
              'Current profile number:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currentInsuranceNumber!,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // nwarriw scanned insurance number
          Text(
            hasCurrentNumber ? 'Scanned number:' : 'Scanned insurance number:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            scannedInsuranceNumber,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),

          // ken bech ybadal number 9dim, nwarriw warning
          if (hasCurrentNumber) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will replace your current insurance number.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),

      // buttons mte3 dialog
      actions: [
        // cancel yrajja3 false
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        const SizedBox(width: 8),

        // save/update yrajja3 true
        AppButton(
          label: hasCurrentNumber ? 'Update' : 'Save to profile',
          icon: Icons.save_outlined,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
      actionsAlignment: MainAxisAlignment.end,
    );
  }
}
