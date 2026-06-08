import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/constat.dart';
import '../../../../core/models/document_scan.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../constat/presentation/widgets/cost_estimation_summary.dart';

// screen mte3 constat detail
// ywarri detail mte3 constat men history, w zeda يستعمل cross-user approval
class ConstatDetailScreen extends ConsumerStatefulWidget {
  const ConstatDetailScreen({
    required this.constatId,
    this.ownerUid,
    super.key,
  });

  // id mte3 constat eli bech n'affichiw detail mte3ou
  final String constatId;

  /// UID of the user who owns the constat. Non-null when navigating from a
  /// cross-user approval notification (User B opening User A's constat).
  /// When present and different from the logged-in user, the screen fetches
  /// the constat from Firestore before rendering.
  // ownerUid ykoun mawjoud ki User B y7el constat mte3 User A men notification
  final String? ownerUid;

  @override
  ConsumerState<ConstatDetailScreen> createState() =>
      _ConstatDetailScreenState();
}

class _ConstatDetailScreenState extends ConsumerState<ConstatDetailScreen> {
  // loading state mte3 cross-user constat
  bool _crossUserLoading = false;

  // error message ken cross-user loading tfشل
  String? _crossUserError;

  @override
  void initState() {
    super.initState();

    // ki screen tet7al, nloadiw cross-user constat ken lzem
    _loadCrossUserConstatIfNeeded();
  }

  // tloadi constat mte3 user ekher ken ownerUid different men current user
  Future<void> _loadCrossUserConstatIfNeeded() async {
    final ownerUid = widget.ownerUid;

    // ken ma famech ownerUid, ma famech cross-user case
    if (ownerUid == null || ownerUid.isEmpty) return;

    // current logged-in user uid
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // ken owner howa current user, ma nloadiwch cross-user
    if (ownerUid == currentUid) return;

    // Already in state (e.g. navigating back to this screen).
    // ken constat deja mawjoud fi state, ma n3awdouch nloadiw
    final notifier = ref.read(appSessionProvider.notifier);
    if (notifier.getConstatById(widget.constatId) != null) return;

    // nbadlou state l loading
    setState(() {
      _crossUserLoading = true;
      _crossUserError = null;
    });

    try {
      // nloadiw constat men Firestore w n7otou fi session state
      await notifier.loadCrossUserConstatIntoState(ownerUid, widget.constatId);
    } catch (e) {
      // error fi loading
      if (mounted) {
        setState(() => _crossUserError = 'Could not load constat: $e');
      }
    }

    // nوقفou loading
    if (mounted) setState(() => _crossUserLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Watch the session so the screen reacts to state changes (Party B saves,
    // approval responses, cross-user constat injection).
    // nwatchiw session bech UI تتبدل ki state تتبدل
    final session = ref.watch(appSessionProvider);

    // loading view mte3 cross-user fetch
    if (_crossUserLoading) {
      return AppPageScaffold(
        title: 'Loading…',
        subtitle: 'Fetching constat details',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // error view ken cross-user fetch tfشل
    if (_crossUserError != null) {
      return AppPageScaffold(
        title: 'Error',
        subtitle: 'Unable to load constat',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.textDisabled),
              const SizedBox(height: 16),
              Text(_crossUserError!),
              const SizedBox(height: 24),
              AppButton(
                label: 'Back',
                icon: Icons.arrow_back,
                onPressed: () => context.go(RouteNames.historyPath),
              ),
            ],
          ),
        ),
      );
    }

    // njibou constat men session b id
    final constat = ref
        .read(appSessionProvider.notifier)
        .getConstatById(widget.constatId);

    // ken constat mawjoudch
    if (constat == null) {
      return AppPageScaffold(
        title: 'Constat not found',
        subtitle: 'Unable to load details',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.textDisabled),
              const SizedBox(height: 16),
              const Text('Constat not found'),
              const SizedBox(height: 24),
              AppButton(
                label: 'Back to History',
                icon: Icons.arrow_back,
                onPressed: () => context.go(RouteNames.historyPath),
              ),
            ],
          ),
        ),
      );
    }

    // njibou photo scans linked bel constat
    // owner: match by ID from session scans.
    // cross-user (Party B): session has no owner scans → fall back to the
    // compact snapshot embedded in the constat at approval-request time.
    final sessionPhotoScans = constat.photoScanIds
        .map((id) => session.scans.where((scan) => scan.id == id).firstOrNull)
        .whereType<DocumentScan>()
        .toList();
    final photoScans = sessionPhotoScans.isNotEmpty
        ? sessionPhotoScans
        : (constat.photoScansSnapshot ?? const <Map<String, dynamic>>[])
              .map((data) {
                try {
                  return DocumentScan.fromJson(data);
                } catch (_) {
                  return null;
                }
              })
              .whereType<DocumentScan>()
              .toList();

    // true ken constat mazal draft
    final isDraft = constat.status == ConstatStatus.draft;

    // next step ken draft
    final nextStep = isDraft ? _determineNextStep(constat) : null;

    final theme = Theme.of(context);

    // true ken dark mode
    final isDarkMode = theme.brightness == Brightness.dark;

    return AppPageScaffold(
      // title howa reference number
      title: constat.referenceNumber,

      // subtitle howa status
      subtitle: _statusLabel(constat.status),

      // body mte3 detail
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // General Info Section
          // section generale: status, created, updated, submitted
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: isDarkMode
                  ? LinearGradient(
                      colors: [
                        theme.colorScheme.surface,
                        theme.colorScheme.surface.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: isDraft
                          ? [const Color(0xFFFFF5EA), const Color(0xFFFFFCF7)]
                          : [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // icon يتبدل حسب draft wala submitted
                Icon(
                  isDraft ? Icons.edit_document : Icons.check_circle_outline,
                  size: 40,
                  color: isDraft ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(height: 20),

                // reference number
                Text(
                  constat.referenceNumber,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                // description حسب status
                Text(
                  isDraft
                      ? 'This constat is still in draft status. You can continue editing it.'
                      : 'This constat has been submitted successfully.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 16),

                // status chip
                _InfoChip(
                  label: 'Status',
                  value: _statusLabel(constat.status),
                  color: isDraft ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(height: 8),

                // created date
                _InfoChip(
                  label: 'Created',
                  value: _formatDateTime(constat.createdAt),
                ),
                const SizedBox(height: 8),

                // updated date
                _InfoChip(
                  label: 'Last updated',
                  value: _formatDateTime(constat.updatedAt),
                ),

                // submitted date ken mawjoud
                if (constat.submittedAt != null) ...[
                  const SizedBox(height: 8),
                  _InfoChip(
                    label: 'Submitted',
                    value: _formatDateTime(constat.submittedAt!),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Approval Status Section
          // section mte3 approval status ken fama approval request
          if (constat.approvalStatus != 'none') ...[
            SectionCard(
              title: 'Approval status',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // banner ywarri pending/accepted/rejected
                  _ApprovalStatusBanner(
                    status: constat.approvalStatus,
                    requestedAt: constat.approvalRequestedAt,
                    respondedAt: constat.approvalRespondedAt,
                  ),

                  // ken current user howa Party B w request pending, yنجّم يقبل ولا يرفض
                  if (constat.approvalStatus == 'pending' &&
                      constat.approvalRequestedToUid ==
                          session.currentUser.id) ...[
                    const SizedBox(height: 16),
                    Text(
                      'This constat is waiting for your approval.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // accept / reject buttons
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Accept',
                            icon: Icons.check_circle,
                            onPressed: () => _handleApprovalResponse(
                              context,
                              ref,
                              widget.constatId,
                              accepted: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: 'Reject',
                            icon: Icons.cancel,
                            variant: AppButtonVariant.secondary,
                            onPressed: () => _handleApprovalResponse(
                              context,
                              ref,
                              widget.constatId,
                              accepted: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Party B Completion Section (for pending approvals)
          // section tطلب men Party B ykamel info mte3ou 9bal accept
          if (constat.approvalStatus == 'pending' &&
              constat.approvalRequestedToUid == session.currentUser.id) ...[
            SectionCard(
              title: 'Complete your information',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // info box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColors.info.withAlpha(40)
                          : AppColors.infoLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withAlpha(
                          isDarkMode ? 70 : 50,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isDarkMode
                              ? AppColors.info.withAlpha(210)
                              : AppColors.info,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Before accepting, please complete your driver, vehicle, and insurance information.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDarkMode
                                  ? AppColors.info.withAlpha(210)
                                  : AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // status mte3 info completed wala le
                  _PartyBCompletionStatus(
                    constat: constat,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 16),

                  // button yemchi lel party B info screen
                  AppButton(
                    label: 'Complete my information',
                    icon: Icons.edit_document,
                    onPressed: () => context.push(
                      RouteNames.partyBInfoPath(
                        widget.constatId,
                        ownerUid: widget.ownerUid,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Party B Information Display (if completed)
          // section taffichi info mte3 Party B ken completed
          if (constat.partyBCompletedAt != null) ...[
            SectionCard(
              title: 'Party B information',
              subtitle: 'Completed by the second party',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // driver Party B
                  if (constat.partyBDriverSnapshot != null) ...[
                    Text(
                      'Driver',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      'Full name',
                      (constat.partyBDriverSnapshot?['fullName'] as String?) ??
                          '--',
                    ),
                    _DetailRow(
                      'License number',
                      (constat.partyBDriverSnapshot?['licenseNumber']
                              as String?) ??
                          '--',
                    ),
                    const SizedBox(height: 16),
                  ],

                  // vehicle Party B
                  if (constat.partyBVehicleSnapshot != null) ...[
                    Text(
                      'Vehicle',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      'Plate number',
                      (constat.partyBVehicleSnapshot?['plateNumber']
                              as String?) ??
                          '--',
                    ),
                    _DetailRow(
                      'Brand',
                      (constat.partyBVehicleSnapshot?['brand'] as String?) ??
                          '--',
                    ),
                    const SizedBox(height: 16),
                  ],

                  // insurance Party B
                  if (constat.partyBInsuranceSnapshot != null) ...[
                    Text(
                      'Insurance',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      'Insurance number',
                      (constat.partyBInsuranceSnapshot?['insuranceNumber']
                              as String?) ??
                          '--',
                    ),
                    _DetailRow(
                      'Company name',
                      (constat.partyBInsuranceSnapshot?['companyName']
                              as String?) ??
                          '--',
                    ),
                  ],
                  const SizedBox(height: 8),

                  // completed date
                  Text(
                    'Completed: ${_formatDateTime(constat.partyBCompletedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Accident Info Section
          // section mte3 accident info
          SectionCard(
            title: 'Accident information',
            icon: Icons.car_crash_outlined,
            iconColor: AppColors.error,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  'Date and time',
                  _formatDateTime(constat.accidentDateTime),
                ),
                _DetailRow('Location', constat.accidentLocation ?? '--'),
                _LongTextBlock('Description', constat.accidentDescription ?? '--'),

                // notes ken mawjoudin
                if (constat.notes != null && constat.notes!.isNotEmpty)
                  _LongTextBlock('Notes', constat.notes!),

                // detected entities ken mawjoudin
                if (constat.extractedEntities != null &&
                    constat.extractedEntities!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Detected details:', style: theme.textTheme.labelMedium),
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
                        backgroundColor: isDarkMode
                            ? AppColors.info.withAlpha(70)
                            : AppColors.infoLight,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Driver Info Section
          // section mte3 driver Party A
          SectionCard(
            title: 'Driver information',
            icon: Icons.person_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  'Full name',
                  (constat.driverSnapshot?['fullName'] as String?) ?? '--',
                ),
                _DetailRow(
                  'License number',
                  (constat.driverSnapshot?['licenseNumber'] as String?) ?? '--',
                ),
                _DetailRow(
                  'CIN / National ID',
                  (constat.driverSnapshot?['nationalId'] as String?) ?? '--',
                ),
                _DetailRow(
                  'Phone number',
                  (constat.driverSnapshot?['phoneNumber'] as String?) ?? '--',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Vehicle Info Section
          // section mte3 vehicle Party A
          SectionCard(
            title: 'Vehicle information',
            icon: Icons.directions_car_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  'Plate number',
                  (constat.vehicleSnapshot?['plateNumber'] as String?) ?? '--',
                ),
                _DetailRow(
                  'Brand',
                  (constat.vehicleSnapshot?['brand'] as String?) ?? '--',
                ),
                _DetailRow(
                  'Model',
                  (constat.vehicleSnapshot?['model'] as String?) ?? '--',
                ),
                _DetailRow(
                  'VIN',
                  (constat.vehicleSnapshot?['vin'] as String?) ?? '--',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Party A Insurance
          // assurance mte3 Party A
          SectionCard(
            title: 'My insurance (Party A)',
            icon: Icons.shield_outlined,
            iconColor: AppColors.info,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  'Insurance number',
                  (constat.partyAInsuranceSnapshot?['insuranceNumber']
                          as String?) ??
                      (constat.insuranceSnapshot?['insuranceNumber']
                          as String?) ??
                      '--',
                ),
                _DetailRow(
                  'Company name',
                  (constat.partyAInsuranceSnapshot?['companyName']
                          as String?) ??
                      (constat.insuranceSnapshot?['companyName'] as String?) ??
                      '--',
                ),
                _DetailRow(
                  'Policy holder',
                  (constat.partyAInsuranceSnapshot?['policyHolderName']
                          as String?) ??
                      (constat.insuranceSnapshot?['policyHolderName']
                          as String?) ??
                      '--',
                ),
                _DetailRow(
                  'Policy type',
                  (constat.partyAInsuranceSnapshot?['policyType'] as String?) ??
                      (constat.insuranceSnapshot?['policyType'] as String?) ??
                      '--',
                ),
              ],
            ),
          ),

          // target insurance Party B ken mawjoud
          if (constat.partyBTargetInsuranceSnapshot != null) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Other party target insurance',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    'Insurance number',
                    (constat.partyBTargetInsuranceSnapshot?['insuranceNumber']
                            as String?) ??
                        '--',
                  ),
                  _DetailRow(
                    'Company name',
                    (constat.partyBTargetInsuranceSnapshot?['companyName']
                            as String?) ??
                        '--',
                  ),
                  _DetailRow(
                    'Policy holder',
                    (constat.partyBTargetInsuranceSnapshot?['policyHolderName']
                            as String?) ??
                        '--',
                  ),
                  _DetailRow(
                    'Policy type',
                    (constat.partyBTargetInsuranceSnapshot?['policyType']
                            as String?) ??
                        '--',
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Damage Photos Section
          // section mte3 photos damage
          SectionCard(
            title: 'Damage photos',
            icon: Icons.camera_alt_outlined,
            iconColor: AppColors.warning,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // nombre photos attached
                Text(
                  '${photoScans.length} photo(s) attached',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),

                // ken ma famech photos
                if (photoScans.isEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No damage photos added yet',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),

                  // thumbnails mte3 photos
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: photoScans.map((scan) {
                      return _PhotoThumbnail(scan: scan);
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // damage cost estimate section — shown only when scan data exists
          if (CostEstimationSummary.hasData(photoScans)) ...[
            SectionCard(
              title: 'Damage cost estimate',
              icon: Icons.monetization_on_outlined,
              iconColor: AppColors.success,
              child: CostEstimationSummary(photoScans: photoScans),
            ),
            const SizedBox(height: 16),
          ],

          // Actions Section
          // ken draft, nwarriw button continue editing
          if (isDraft && nextStep != null) ...[
            SectionCard(
              title: 'Continue draft',
              icon: Icons.edit_outlined,
              iconColor: AppColors.warning,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // next step info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withAlpha(70),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_forward_outlined,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Next: ${nextStep['label']}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // continue editing button
                  AppButton(
                    label: 'Continue editing',
                    icon: Icons.edit,
                    onPressed: () => context.push(nextStep['route'] as String),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Back Button
          // button yarja3 lel history
          AppButton(
            label: 'Back to History',
            icon: Icons.arrow_back,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.go(RouteNames.historyPath),
          ),
        ],
      ),
    );
  }

  // tحدد next step حسب fields الناقصة fil draft
  Map<String, dynamic>? _determineNextStep(Constat constat) {
    // Check accident info
    // ken accident info ناقصة
    if (constat.accidentDateTime == null ||
        constat.accidentLocation == null ||
        constat.accidentLocation!.isEmpty) {
      return {
        'step': 2,
        'label': 'Step 2 of 8 - Accident information',
        'route': RouteNames.accidentInfoPath,
      };
    }

    // Check driver info
    // ken driver info ناقصة
    if (constat.driverSnapshot == null ||
        (constat.driverSnapshot?['fullName'] as String?)?.isEmpty == true) {
      return {
        'step': 3,
        'label': 'Step 3 of 8 - Driver information',
        'route': RouteNames.driverInfoPath,
      };
    }

    // Check vehicle info
    // ken vehicle info ناقصة
    if (constat.vehicleSnapshot == null ||
        (constat.vehicleSnapshot?['plateNumber'] as String?)?.isEmpty == true) {
      return {
        'step': 4,
        'label': 'Step 4 of 8 - Vehicle information',
        'route': RouteNames.vehicleInfoPath,
      };
    }

    // Check insurance info (Party A)
    // ken assurance Party A ناقصة
    final partyAInsuranceNumber =
        (constat.partyAInsuranceSnapshot?['insuranceNumber'] as String?) ??
        (constat.insuranceSnapshot?['insuranceNumber'] as String?);
    if (partyAInsuranceNumber == null || partyAInsuranceNumber.isEmpty) {
      return {
        'step': 5,
        'label': 'Step 5 of 8 - Insurance information',
        'route': RouteNames.insuranceInfoPath,
      };
    }

    // Check photos
    // ken photos ناقصين
    if (constat.photoScanIds.isEmpty) {
      return {
        'step': 6,
        'label': 'Step 6 of 8 - Damage photos',
        'route': RouteNames.photosDamagePath,
      };
    }

    // All basic info complete, go to review
    // ken kol chay basic mكمّل, next howa review
    return {
      'step': 7,
      'label': 'Step 7 of 8 - Review and signature',
      'route': RouteNames.constatReviewPath,
    };
  }
}

// full-width block for long text fields: label on top, value below
class _LongTextBlock extends StatelessWidget {
  const _LongTextBlock(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = value == '--' || value.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isEmpty
                  ? AppColors.textDisabled
                  : theme.colorScheme.onSurface,
              fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// row reusable ywarri label w value fi details
class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = value == '--' || value.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isEmpty
                    ? AppColors.textDisabled
                    : theme.colorScheme.onSurface,
                fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// row sghira ywarri info chip/value
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value, this.color});

  // label mte3 info
  final String label;

  // value mte3 info
  final String value;

  // couleur optionnelle
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // label
        Text(
          '$label: ',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),

        // value
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// thumbnail mte3 damage photo
class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.scan});

  // scan document mte3 photo
  final DocumentScan scan;

  @override
  Widget build(BuildContext context) {
    // نحددو source mte3 image: local file, thumbnail URL wala file URL
    final hasLocalFile =
        scan.localFilePath != null && scan.localFilePath!.isNotEmpty;
    final hasThumbnail =
        scan.thumbnailUrl != null && scan.thumbnailUrl!.isNotEmpty;
    final hasFileUrl = scan.fileUrl != null && scan.fileUrl!.isNotEmpty;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),

        // priority: local file ثم thumbnail ثم fileUrl ثم placeholder
        child: hasLocalFile
            ? Image.file(
                File(scan.localFilePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _PlaceholderPhoto(scan: scan);
                },
              )
            : hasThumbnail
            ? Image.network(
                scan.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _PlaceholderPhoto(scan: scan);
                },
              )
            : hasFileUrl
            ? Image.network(
                scan.fileUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _PlaceholderPhoto(scan: scan);
                },
              )
            : _PlaceholderPhoto(scan: scan),
      ),
    );
  }
}

// placeholder ken photo ma تنجمch tloadi
class _PlaceholderPhoto extends StatelessWidget {
  const _PlaceholderPhoto({required this.scan});

  // scan document
  final DocumentScan scan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // true ken dark mode
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? theme.colorScheme.surface : AppColors.surfaceAlt,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // image icon
          Icon(
            Icons.image_outlined,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            size: 32,
          ),
          const SizedBox(height: 4),

          // text photo
          Text(
            'Photo',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 10,
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
  return DateFormat('yyyy-MM-dd HH:mm').format(value);
}

// t7awel constat status l label readable
String _statusLabel(ConstatStatus status) {
  return switch (status) {
    ConstatStatus.draft => 'Draft',
    ConstatStatus.submitted => 'Submitted',
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

// taccepti wala trejecti approval request
Future<void> _handleApprovalResponse(
  BuildContext context,
  WidgetRef ref,
  String constatId, {
  required bool accepted,
}) async {
  // session notifier
  final notifier = ref.read(appSessionProvider.notifier);

  // njibou constat
  final constat = notifier.getConstatById(constatId);

  // Check if Party B info is complete before accepting
  // 9bal accept, لازم Party B يكمل driver/vehicle/insurance info
  if (accepted && constat != null && !notifier.isPartyBInfoComplete(constat)) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please complete your driver, vehicle and insurance information first.',
        ),
        backgroundColor: AppColors.warning,
        duration: Duration(seconds: 3),
      ),
    );
    return;
  }

  // Show loading indicator
  // feedback loading lel user
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(accepted ? 'Accepting...' : 'Rejecting...'),
      duration: const Duration(seconds: 1),
    ),
  );

  // nبعثou response lel approval
  final success = await notifier.respondToConstatApproval(
    constatId: constatId,
    accepted: accepted,
  );

  if (!context.mounted) return;

  // feedback حسب result
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          accepted
              ? 'Constat accepted successfully'
              : 'Constat rejected successfully',
        ),
        backgroundColor: accepted ? AppColors.success : AppColors.warning,
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to respond to approval request'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

// banner ywarri approval status
class _ApprovalStatusBanner extends StatelessWidget {
  const _ApprovalStatusBanner({
    required this.status,
    this.requestedAt,
    this.respondedAt,
  });

  // approval status
  final String status;

  // date request
  final DateTime? requestedAt;

  // date response
  final DateTime? respondedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // true ken dark mode
    final isDarkMode = theme.brightness == Brightness.dark;

    Color backgroundColor;
    Color textColor;
    IconData icon;
    String label;
    String description;

    // nختارو UI حسب approval status
    switch (status) {
      case 'pending':
        backgroundColor = isDarkMode
            ? AppColors.warning.withAlpha(55)
            : AppColors.warningLight;
        textColor = isDarkMode
            ? AppColors.warning
            : AppColors.warning;
        icon = Icons.pending_outlined;
        label = 'Pending approval';
        description = 'Waiting for the other party to review and respond.';
        break;
      case 'accepted':
        backgroundColor = isDarkMode
            ? AppColors.success.withAlpha(55)
            : AppColors.successLight;
        textColor = AppColors.success;
        icon = Icons.check_circle_outline;
        label = 'Accepted';
        description = 'The other party has accepted this constat.';
        break;
      case 'rejected':
        backgroundColor = isDarkMode
            ? AppColors.error.withAlpha(55)
            : AppColors.errorLight;
        textColor = AppColors.error;
        icon = Icons.cancel_outlined;
        label = 'Rejected';
        description = 'The other party has rejected this constat.';
        break;
      default:
        backgroundColor = isDarkMode
            ? theme.colorScheme.surface
            : AppColors.surfaceAlt;
        textColor = theme.colorScheme.onSurface;
        icon = Icons.info_outline;
        label = 'No approval request';
        description = 'This constat does not have an approval request.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header mte3 status
          Row(
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // description
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor.withValues(alpha: 0.9),
            ),
          ),

          // requested date
          if (requestedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Requested: ${_formatDateTime(requestedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ],

          // responded date
          if (respondedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Responded: ${_formatDateTime(respondedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// widget ywarri chnowa Party B kamel w chnowa mazal
class _PartyBCompletionStatus extends StatelessWidget {
  const _PartyBCompletionStatus({
    required this.constat,
    required this.isDarkMode,
  });

  // constat actuel
  final Constat constat;

  // true ken dark mode
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    // driver info complete?
    final hasDriver =
        constat.partyBDriverSnapshot != null &&
        (constat.partyBDriverSnapshot?['fullName'] as String?)?.isNotEmpty ==
            true;

    // vehicle info complete?
    final hasVehicle =
        constat.partyBVehicleSnapshot != null &&
        (constat.partyBVehicleSnapshot?['plateNumber'] as String?)
                ?.isNotEmpty ==
            true;

    // insurance info complete?
    final hasInsurance =
        constat.partyBInsuranceSnapshot != null &&
        (constat.partyBInsuranceSnapshot?['insuranceNumber'] as String?)
                ?.isNotEmpty ==
            true;

    return Column(
      children: [
        _CompletionStatusRow(
          label: 'Driver information',
          isComplete: hasDriver,
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 8),
        _CompletionStatusRow(
          label: 'Vehicle information',
          isComplete: hasVehicle,
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 8),
        _CompletionStatusRow(
          label: 'Insurance information',
          isComplete: hasInsurance,
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }
}

// row ywarri completed wala not completed
class _CompletionStatusRow extends StatelessWidget {
  const _CompletionStatusRow({
    required this.label,
    required this.isComplete,
    required this.isDarkMode,
  });

  // label mte3 row
  final String label;

  // true ken complete
  final bool isComplete;

  // true ken dark mode
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // check icon wala empty circle
        Icon(
          isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 20,
          color: isComplete
              ? AppColors.success
              : theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        const SizedBox(width: 12),

        // label
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isComplete
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}