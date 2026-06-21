import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/models/constat.dart';
import '../../../../core/models/document_scan.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/cost_estimation_summary.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';

// screen mte3 review draft
// ywarri kol data eli user 3abbaha 9bal signature w submit
class ConstatReviewScreen extends ConsumerWidget {
  const ConstatReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // nwatchiw session bech njibou active constat w profiles
    final session = ref.watch(appSessionProvider);

    // constat draft eli user yekhdem 3lih
    final constat = session.activeConstat;

    // profiles principaux mte3 current user
    final driver = session.mainDriverProfile;
    final vehicle = session.mainVehicleProfile;
    final insurance = session.mainInsuranceProfile;

    // nombre mte3 scans/photos linked bel constat bla duplication
    final linkedScanCount = {
      ...?constat?.photoScanIds,
      ...?constat?.supportingDocumentScanIds,
    }.length;

    // photo scans bech njibou cost estimation data
    final photoScans = constat == null
        ? const <DocumentScan>[]
        : session.scans
            .where((s) => constat.photoScanIds.contains(s.id))
            .toList();

    final theme = Theme.of(context);

    // true ken dark mode
    final isDark = theme.brightness == Brightness.dark;

    return AppPageScaffold(
      title: 'Vérification',
      subtitle: 'Vérification du brouillon',
      currentStep: 7,
      totalSteps: 8,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // hero card mte3 review step
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      colors: [
                        theme.colorScheme.surface,
                        theme.colorScheme.surface.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFFFF5EA), Color(0xFFFFFCF7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // icon mte3 review
                Icon(
                  Icons.fact_check_outlined,
                  size: 40,
                  color: isDark
                      ? theme.colorScheme.primary
                      : const Color(0xFF124170),
                ),
                const SizedBox(height: 20),

                Text(
                  'Vérification du brouillon',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  'Vérifiez la déclaration assemblée avant de recueillir la confirmation et la signature des parties impliquées.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // section mte3 accident info
          SectionCard(
            title: 'Informations accident',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReviewRow(
                  'Date et heure',
                  _formatDateTime(constat?.accidentDateTime),
                ),
                _ReviewRow('Lieu', constat?.accidentLocation ?? '--'),
                _ReviewLongBlock('Description', constat?.accidentDescription ?? '--'),

                if (constat?.extractedEntities != null &&
                    constat!.extractedEntities!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Détails détectés :', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: constat.extractedEntities!.map((entity) {
                      return Chip(
                        avatar: Icon(
                          _getEntityIcon(entity['type'] as String),
                          size: 16,
                        ),
                        label: Text(
                          '${entity['type']}: ${entity['text']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: isDark
                            ? Colors.blue.shade900.withValues(alpha: 0.3)
                            : Colors.blue.shade50,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // section mte3 driver info
          SectionCard(
            title: 'Conducteur',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReviewRow(
                  'Nom complet',
                  (constat?.driverSnapshot?['fullName'] as String?) ??
                      driver?.fullName ??
                      '--',
                ),
                _ReviewRow(
                  'Numéro de permis',
                  (constat?.driverSnapshot?['licenseNumber'] as String?) ??
                      driver?.licenseNumber ??
                      '--',
                ),
                _ReviewRow(
                  'CIN / Carte nationale',
                  (constat?.driverSnapshot?['nationalId'] as String?) ??
                      driver?.nationalId ??
                      '--',
                ),
                _ReviewRow(
                  'Téléphone',
                  (constat?.driverSnapshot?['phoneNumber'] as String?) ??
                      driver?.phoneNumber ??
                      '--',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // section mte3 vehicle info
          SectionCard(
            title: 'Véhicule',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReviewRow(
                  'Immatriculation',
                  (constat?.vehicleSnapshot?['plateNumber'] as String?) ??
                      vehicle?.plateNumber ??
                      '--',
                ),
                _ReviewRow(
                  'Marque',
                  (constat?.vehicleSnapshot?['brand'] as String?) ??
                      vehicle?.brand ??
                      '--',
                ),
                _ReviewRow(
                  'Modèle',
                  (constat?.vehicleSnapshot?['model'] as String?) ??
                      vehicle?.model ??
                      '--',
                ),
                _ReviewRow(
                  'VIN',
                  (constat?.vehicleSnapshot?['vin'] as String?) ??
                      vehicle?.vin ??
                      '--',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // section mte3 insurance Party A
          SectionCard(
            title: 'Mon assurance (Partie A)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReviewRow(
                  'Numéro d\'assurance',
                  (constat?.partyAInsuranceSnapshot?['insuranceNumber']
                          as String?) ??
                      (constat?.insuranceSnapshot?['insuranceNumber']
                          as String?) ??
                      insurance?.insuranceNumber ??
                      '--',
                ),
                _ReviewRow(
                  'Compagnie',
                  (constat?.partyAInsuranceSnapshot?['companyName']
                          as String?) ??
                      (constat?.insuranceSnapshot?['companyName'] as String?) ??
                      insurance?.companyName ??
                      '--',
                ),
                _ReviewRow(
                  'Souscripteur',
                  (constat?.partyAInsuranceSnapshot?['policyHolderName']
                          as String?) ??
                      (constat?.insuranceSnapshot?['policyHolderName']
                          as String?) ??
                      insurance?.policyHolderName ??
                      '--',
                ),
                _ReviewRow(
                  'Type de contrat',
                  (constat?.partyAInsuranceSnapshot?['policyType']
                          as String?) ??
                      (constat?.insuranceSnapshot?['policyType'] as String?) ??
                      insurance?.policyType ??
                      '--',
                ),

                // warning ken insurance number mte3 Party A mawjoudch
                if (((constat?.partyAInsuranceSnapshot?['insuranceNumber'] ??
                                constat?.insuranceSnapshot?['insuranceNumber'])
                            as String?)
                        ?.trim()
                        .isEmpty ??
                    true) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Votre numéro d\'assurance est requis avant la soumission',
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // section mte3 target insurance Party B ken mawjoud
          if (constat?.partyBTargetInsuranceSnapshot != null) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Assurance autre partie',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReviewRow(
                    'Numéro d\'assurance',
                    (constat?.partyBTargetInsuranceSnapshot?['insuranceNumber']
                            as String?) ??
                        '--',
                  ),
                  _ReviewRow(
                    'Compagnie',
                    (constat?.partyBTargetInsuranceSnapshot?['companyName']
                            as String?) ??
                        '--',
                  ),
                  _ReviewRow(
                    'Souscripteur',
                    (constat?.partyBTargetInsuranceSnapshot?['policyHolderName']
                            as String?) ??
                        '--',
                  ),
                  _ReviewRow(
                    'Type de contrat',
                    (constat?.partyBTargetInsuranceSnapshot?['policyType']
                            as String?) ??
                        '--',
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // section mte3 draft status
          SectionCard(
            title: 'Statut du brouillon',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReviewRow(
                  'Statut',
                  _statusLabel(constat?.status ?? ConstatStatus.draft),
                ),
                _ReviewRow('Photos / scans liés', linkedScanCount.toString()),
                _ReviewRow(
                  'Dernier scan',
                  session.activeScan?.scanType.value ?? '--',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // cost estimation section — shown only when damage scans carry AI data
          if (CostEstimationSummary.hasData(photoScans)) ...[
            SectionCard(
              title: 'Estimation des dégâts',
              child: CostEstimationSummary(photoScans: photoScans),
            ),
            const SizedBox(height: 16),
          ],

          // section mte3 next action
          SectionCard(
            title: 'Actions',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  label: 'Continuer vers la signature',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () =>
                      context.push(RouteNames.constatSignaturePath),
                ),
                const SizedBox(height: 12),

                AppButton(
                  label: 'Retour aux photos et dégâts',
                  icon: Icons.arrow_back_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.push(RouteNames.photosDamagePath),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// full-width block for long text fields in review: label on top, value below
class _ReviewLongBlock extends StatelessWidget {
  const _ReviewLongBlock(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// row reusable taffichi label w value fi review
class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);

  // label mte3 field
  final String label;

  // value mte3 field
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // label
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // value
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// tformat DateTime l string readable
String _formatDateTime(DateTime? value) {
  if (value == null) return '--';
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}-$month-$day $hour:$minute';
}

// t7awel constat status l label readable
String _statusLabel(ConstatStatus status) {
  return switch (status) {
    ConstatStatus.draft => 'Brouillon',
    ConstatStatus.submitted => 'Soumis',
  };
}

// trajja3 icon حسب entity type
IconData _getEntityIcon(String type) {
  switch (type) {
    case 'Date':
      return Icons.calendar_today;
    case 'Phone':
      return Icons.phone;
    case 'Address':
      return Icons.location_on;
    case 'Email':
      return Icons.email;
    case 'Money':
      return Icons.attach_money;
    default:
      return Icons.label;
  }
}
