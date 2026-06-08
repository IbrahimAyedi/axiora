import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/models/constat.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';

// screen mte3 success ba3d ma user ysubmiti constat
// ywarri summary w approval status ken fama Party B
class ConstatSuccessScreen extends ConsumerWidget {
  const ConstatSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // nwatchiw session bech njibou active constat
    final session = ref.watch(appSessionProvider);

    // constat eli tsubmita
    final constat = session.activeConstat;

    // theme mte3 app
    final theme = Theme.of(context);

    // insurance snapshot mte3 Party A
    final partyASnap =
        constat?.partyAInsuranceSnapshot ?? constat?.insuranceSnapshot;

    // insurance target mte3 Party B
    final partyBSnap = constat?.partyBTargetInsuranceSnapshot;

    // true ken fama other party insurance
    final hasPartyB = partyBSnap != null;

    // approval status: none, pending, accepted, rejected
    final approvalStatus = constat?.approvalStatus ?? 'none';

    return AppPageScaffold(
      // title mte3 page
      title: 'Declaration complete',

      // subtitle mte3 page
      subtitle: 'Step 8 of 8',

      // body mte3 page
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // success hero card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EF),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFA5D6B0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // success icon
                const Icon(
                  Icons.task_alt_outlined,
                  size: 40,
                  color: Color(0xFF2E7D32),
                ),
                const SizedBox(height: 20),

                // success title
                Text(
                  'Declaration submitted',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),

                // message yتبدل حسب Party B w approval status
                Text(
                  _submissionMessage(hasPartyB, approvalStatus),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // section mte3 submission summary
          SectionCard(
            title: 'Submission summary',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryRow(
                  'Reference number',
                  constat?.referenceNumber ?? '--',
                ),
                _SummaryRow(
                  'Status',
                  _statusLabel(constat?.status ?? ConstatStatus.draft),
                ),

                // submitted date ken mawjoud
                if (constat?.submittedAt != null)
                  _SummaryRow(
                    'Submitted at',
                    _formatDateTime(constat!.submittedAt!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // section mte3 vehicle summary
          SectionCard(
            title: 'Vehicle',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryRow(
                  'Plate number',
                  (constat?.vehicleSnapshot?['plateNumber'] as String?) ?? '--',
                ),
                _SummaryRow(
                  'Brand',
                  (constat?.vehicleSnapshot?['brand'] as String?) ?? '--',
                ),
                _SummaryRow(
                  'Model',
                  (constat?.vehicleSnapshot?['model'] as String?) ?? '--',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // section mte3 assurance Party A
          SectionCard(
            title: 'My insurance (Party A)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryRow(
                  'Company',
                  (partyASnap?['companyName'] as String?) ??
                      session.mainInsuranceProfile?.companyName ??
                      '--',
                ),
                _SummaryRow(
                  'Insurance number',
                  (partyASnap?['insuranceNumber'] as String?) ??
                      session.mainInsuranceProfile?.insuranceNumber ??
                      '--',
                ),
              ],
            ),
          ),

          // ken fama Party B, nwarriw other party insurance w approval status
          if (hasPartyB) ...[
            const SizedBox(height: 16),

            // section mte3 other party insurance
            SectionCard(
              title: 'Other party insurance',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryRow(
                    'Company',
                    (partyBSnap['companyName'] as String?) ?? '--',
                  ),
                  _SummaryRow(
                    'Insurance number',
                    (partyBSnap['insuranceNumber'] as String?) ?? '--',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // section mte3 approval status
            SectionCard(
              title: 'Approval status',
              child: _ApprovalStatusRow(approvalStatus: approvalStatus),
            ),
          ],
          const SizedBox(height: 16),

          // section mte3 next actions
          SectionCard(
            title: 'Next action',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // return lel dashboard/home
                AppButton(
                  label: 'Return to dashboard',
                  icon: Icons.home_outlined,
                  onPressed: () => context.go(RouteNames.homePath),
                ),
                const SizedBox(height: 12),

                // view history
                AppButton(
                  label: 'View history',
                  icon: Icons.history_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.push(RouteNames.historyPath),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// widget ywarri approval status b icon w color
class _ApprovalStatusRow extends StatelessWidget {
  const _ApprovalStatusRow({required this.approvalStatus});

  // approval status mte3 constat
  final String approvalStatus;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    final String label;

    // nختارو icon/color/message حسب approval status
    switch (approvalStatus) {
      case 'pending':
        icon = Icons.pending_outlined;
        color = Colors.orange.shade700;
        label = "Pending — waiting for the other party's insurer to respond";
      case 'accepted':
        icon = Icons.check_circle_outline;
        color = Colors.green.shade700;
        label = "Accepted — the other party's insurer confirmed";
      case 'rejected':
        icon = Icons.cancel_outlined;
        color = Colors.red.shade700;
        label = "Rejected — the other party's insurer declined";
      default:
        icon = Icons.hourglass_empty_outlined;
        color = Colors.grey.shade600;
        label = 'Sending approval request…';
    }

    return Row(
      children: [
        // status icon
        Icon(icon, color: color),
        const SizedBox(width: 12),

        // status label
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

// row reusable taffichi label w value fi summary
class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  // label mte3 field
  final String label;

  // value mte3 field
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // label
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          const SizedBox(width: 16),

          // value
          Expanded(
            child: Text(
              value.isEmpty ? '--' : value,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// message mte3 success يتبدل حسب fama Party B w approval status
String _submissionMessage(bool hasPartyB, String approvalStatus) {
  if (!hasPartyB) {
    return 'Your constat has been saved to Firebase. You can track it in your history.';
  }
  return switch (approvalStatus) {
    'pending' =>
      "Your constat has been saved to Firebase. An approval request has been sent to the other party's insurer.",
    'accepted' =>
      "Your constat has been accepted by the other party's insurer.",
    'rejected' => "Your constat was rejected by the other party's insurer.",
    _ =>
      "Your constat has been saved to Firebase. Sending approval request to the other party's insurer…",
  };
}

// t7awel status enum l label readable
String _statusLabel(ConstatStatus status) {
  return switch (status) {
    ConstatStatus.draft => 'Draft',
    ConstatStatus.submitted => 'Submitted',
  };
}

// tformat DateTime l string readable
String _formatDateTime(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}-$month-$day $hour:$minute';
}
