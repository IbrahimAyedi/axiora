import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/app_text_input.dart';
import '../../../../core/widgets/section_card.dart';
import '../../data/models/damage_prediction.dart';
import '../../data/services/damage_prediction_service.dart';

// screen mte3 photos and damage
// user ya5ou photos, damage API t7allelhom, w result yetzed lel constat draft
class PhotosDamageScreen extends ConsumerStatefulWidget {
  const PhotosDamageScreen({super.key});

  @override
  ConsumerState<PhotosDamageScreen> createState() => _PhotosDamageScreenState();
}

class _PhotosDamageScreenState extends ConsumerState<PhotosDamageScreen> {
  // controller mte3 evidence note
  late final TextEditingController _evidenceNoteController;

  // image picker bech na5dhou image men camera wala gallery
  final ImagePicker _imagePicker = ImagePicker();

  // state mte3 kol photo slot
  final Map<_DamagePhotoSlot, _DamagePhotoState> _photoStates = {
    _DamagePhotoSlot.frontVehicle: const _DamagePhotoState(),
    _DamagePhotoSlot.damageCloseUp: const _DamagePhotoState(),
  };

  @override
  void initState() {
    super.initState();

    // njibou active draft
    final draft = ref.read(appSessionProvider).activeConstat;

    // njibou old notes ken mawjoudin
    final existingNote = draft?.notes ?? '';

    // n3abbiw evidence note mel old notes
    _evidenceNoteController = TextEditingController(
      text: _extractEvidenceNote(existingNote),
    );
  }

  @override
  void dispose() {
    // nfas5ou controller bech ma ysirch memory leak
    _evidenceNoteController.dispose();
    super.dispose();
  }

  // tsajel damage note w temchi lel review step
  void _continueToReview() {
    ref
        .read(appSessionProvider.notifier)
        .saveDamageDraft(evidenceNote: _evidenceNoteController.text.trim());

    context.push(RouteNames.constatReviewPath);
  }

  // ta5tar image w tba3thha lel damage API
  Future<void> _pickAndAnalyze(
    _DamagePhotoSlot slot,
    ImageSource source,
  ) async {
    // state actuel mte3 slot
    final currentState = _photoStates[slot] ?? const _DamagePhotoState();

    // ken deja fama upload/analyse, nوقفou
    if (currentState.isUploading) return;

    try {
      // na5dhou image men camera wala gallery
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );

      // ken user cancel, ma na3mlou chay
      if (pickedFile == null) return;

      // n7awlou picked file l File
      final image = File(pickedFile.path);

      // source label: camera wala gallery
      final sourceLabel = source == ImageSource.camera ? 'camera' : 'gallery';

      // nupdatew local UI state: image selected + loading
      setState(() {
        _photoStates[slot] = currentState.copyWith(
          localFile: image,
          source: sourceLabel,
          isUploading: true,
          clearPrediction: true,
          clearError: true,
        );
      });

      // njibou vehicle + constat info bech nba3thom lel API
      final session = ref.read(appSessionProvider);
      final vehicle = session.mainVehicleProfile;
      final location = session.activeConstat?.accidentLocation;
      final region = location != null && location.isNotEmpty
          ? location.split(' -').first.trim()
          : null;

      // nبعثou image lel damage prediction service m3a vehicle metadata
      final prediction = await ref
          .read(damagePredictionServiceProvider)
          .predict(
            image,
            vehicleMake: vehicle?.brand,
            vehicleModel: vehicle?.model,
            vehicleYear: vehicle?.firstRegistrationDate?.year.toString(),
            region: region,
          );
      if (!mounted) return;

      // n7adhrou note line mel prediction result
      final noteLine = _noteLineFor(slot, prediction);

      // nzidou wala nupdatew generated note fi evidence note
      _upsertGeneratedNote(slot, noteLine);

      // nsajlou damage photo evidence fi app session
      // hethi tzid scan, upload local photo, w torbtou bel constat
      ref
          .read(appSessionProvider.notifier)
          .recordDamagePhotoEvidence(
            label: slot.label,
            source: sourceLabel,
            localFilePath: image.path,
            annotatedImageUrl: prediction.annotatedImageUrl,
            damageDetected: prediction.damageDetected,
            extractedData: prediction.toScanData(),
            scanNote: noteLine,
            evidenceNote: _evidenceNoteController.text.trim(),
            confidenceScore: prediction.bestConfidence,
          );

      // nupdatew UI b prediction result
      setState(() {
        _photoStates[slot] = (_photoStates[slot] ?? currentState).copyWith(
          prediction: prediction,
          isUploading: false,
          clearError: true,
        );
      });
    } catch (error) {
      if (!mounted) return;

      // ken API wala picker tfشل, nwarriw error
      setState(() {
        _photoStates[slot] = (_photoStates[slot] ?? currentState).copyWith(
          isUploading: false,
          error: _friendlyError(error),
        );
      });
    }
  }

  // tzid note generated wala tbadlou ken deja mawjoud l nafs slot
  void _upsertGeneratedNote(_DamagePhotoSlot slot, String noteLine) {
    final prefix = '${slot.label}:';

    // n7adhrou lines w na7iw old line mte3 nafs slot
    final lines = _evidenceNoteController.text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith(prefix))
        .toList();

    // nzidou note jdida
    lines.add(noteLine);

    // nupdatew text controller
    final text = lines.join('\n');
    _evidenceNoteController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  // ta3mel note line mel slot w prediction summary
  String _noteLineFor(_DamagePhotoSlot slot, DamagePrediction prediction) {
    return '${slot.label}: ${prediction.summary}';
  }

  // tnadhaf error message
  String _friendlyError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('DamagePredictionException: ', '');
  }

  @override
  Widget build(BuildContext context) {
    // session mte3 app
    final session = ref.watch(appSessionProvider);

    // active constat draft
    final draft = session.activeConstat;

    // nombre mte3 scans/photos linked bel constat
    final linkedCount = {
      ...?draft?.photoScanIds,
      ...?draft?.supportingDocumentScanIds,
    }.length;

    // true ken fama photo currently analyzing/uploading
    final isUploading = _photoStates.values.any((state) => state.isUploading);

    return AppPageScaffold(
      title: 'Photos & dégâts',
      subtitle: 'Analyse IA des dommages',
      currentStep: 6,
      totalSteps: 8,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // hero card mte3 photos/damage
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.trustBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // icon mte3 photo
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.white20),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Photos & dégâts',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  'Ajoutez les preuves visuelles, lancez l’analyse IA et obtenez une estimation indicative avant la vérification.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white70,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // section mte3 damage evidence photos
          SectionCard(
            title: 'Preuves photographiques',
            subtitle:
                'Prenez ou importez une photo ; l\'analyse démarre dès la sélection.',
            icon: Icons.add_photo_alternate_outlined,
            iconColor: AppColors.trustBlue,
            child: Column(
              children: [
                // front vehicle photo card
                _DamageEvidenceCard(
                  slot: _DamagePhotoSlot.frontVehicle,
                  state:
                      _photoStates[_DamagePhotoSlot.frontVehicle] ??
                      const _DamagePhotoState(),
                  onCamera: () => _pickAndAnalyze(
                    _DamagePhotoSlot.frontVehicle,
                    ImageSource.camera,
                  ),
                  onGallery: () => _pickAndAnalyze(
                    _DamagePhotoSlot.frontVehicle,
                    ImageSource.gallery,
                  ),
                ),
                const SizedBox(height: 12),

                // damage close-up photo card
                _DamageEvidenceCard(
                  slot: _DamagePhotoSlot.damageCloseUp,
                  state:
                      _photoStates[_DamagePhotoSlot.damageCloseUp] ??
                      const _DamagePhotoState(),
                  onCamera: () => _pickAndAnalyze(
                    _DamagePhotoSlot.damageCloseUp,
                    ImageSource.camera,
                  ),
                  onGallery: () => _pickAndAnalyze(
                    _DamagePhotoSlot.damageCloseUp,
                    ImageSource.gallery,
                  ),
                ),
                const SizedBox(height: 12),

                // linked scans count
                Row(
                  children: [
                    const Icon(
                      Icons.linked_camera_outlined,
                      size: 18,
                      color: AppColors.trustBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$linkedCount photo(s) / scan(s) lié(s) au constat',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // section mte3 damage note
          SectionCard(
            title: 'Note de dégâts',
            subtitle:
                'Pré-remplie par l\'IA, modifiable avant la vérification.',
            icon: Icons.edit_note_outlined,
            iconColor: AppColors.primary,
            child: AppTextInput(
              label: 'Note d\'observation',
              controller: _evidenceNoteController,
              maxLines: 4,
              hint:
                  'Décrivez l\'impact visible, l\'angle, ou tout élément utile',
            ),
          ),
          const SizedBox(height: 16),

          SectionCard(
            title: 'Actions',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  label: 'Continuer vers la vérification',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: isUploading ? null : _continueToReview,
                ),

                if (isUploading) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Analyse IA en cours, veuillez patienter...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),

                AppButton(
                  label: 'Retour aux informations assurance',
                  icon: Icons.arrow_back_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.push(RouteNames.insuranceInfoPath),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// slots mte3 damage photos
enum _DamagePhotoSlot { frontVehicle, damageCloseUp }

// extension t3tina label/hint/icon lel kol slot
extension _DamagePhotoSlotDetails on _DamagePhotoSlot {
  // label mte3 slot
  String get label {
    return switch (this) {
      _DamagePhotoSlot.frontVehicle => 'Vue du véhicule',
      _DamagePhotoSlot.damageCloseUp => 'Gros plan dégâts',
    };
  }

  // hint mte3 slot
  String get hint {
    return switch (this) {
      _DamagePhotoSlot.frontVehicle => 'Photo large du véhicule accidenté',
      _DamagePhotoSlot.damageCloseUp => 'Photo rapprochée de la zone impactée',
    };
  }

  // icon mte3 slot
  IconData get icon {
    return switch (this) {
      _DamagePhotoSlot.frontVehicle => Icons.directions_car_filled_outlined,
      _DamagePhotoSlot.damageCloseUp => Icons.center_focus_strong_outlined,
    };
  }
}

// local UI state mte3 photo slot
class _DamagePhotoState {
  const _DamagePhotoState({
    this.localFile,
    this.source,
    this.prediction,
    this.isUploading = false,
    this.error,
  });

  // local image file selected
  final File? localFile;

  // source: camera wala gallery
  final String? source;

  // prediction result men damage API
  final DamagePrediction? prediction;

  // true waqt analyzing/uploading
  final bool isUploading;

  // error message ken fama problem
  final String? error;

  // copyWith ta3mel state jdida m3a update mou3ayen
  _DamagePhotoState copyWith({
    File? localFile,
    String? source,
    DamagePrediction? prediction,
    bool? isUploading,
    String? error,
    bool clearPrediction = false,
    bool clearError = false,
  }) {
    return _DamagePhotoState(
      localFile: localFile ?? this.localFile,
      source: source ?? this.source,
      prediction: clearPrediction ? null : prediction ?? this.prediction,
      isUploading: isUploading ?? this.isUploading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// card mte3 photo damage wa7da
class _DamageEvidenceCard extends StatelessWidget {
  const _DamageEvidenceCard({
    required this.slot,
    required this.state,
    required this.onCamera,
    required this.onGallery,
  });

  // slot type
  final _DamagePhotoSlot slot;

  // state mte3 slot
  final _DamagePhotoState state;

  // action camera
  final VoidCallback onCamera;

  // action gallery
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final prediction = state.prediction;

    // text yوضح source/hint
    final source = state.source == null
        ? slot.hint
        : '${slot.hint} - ${state.source == 'camera' ? 'Caméra' : 'Galerie'}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // card header: icon, label, source w status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // icon box
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(slot.icon, size: 22, color: AppColors.trustBlue),
              ),
              const SizedBox(width: 12),

              // title w source
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      source,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // status pill
              _DamageStatusPill(state: state),
            ],
          ),
          const SizedBox(height: 12),

          // image preview: local wala annotated image
          _DamageImagePreview(state: state, slot: slot),
          const SizedBox(height: 12),

          // camera/upload buttons
          _DamagePhotoActions(
            isUploading: state.isUploading,
            onCamera: onCamera,
            onGallery: onGallery,
          ),

          // prediction summary ken mawjoud
          if (prediction != null) ...[
            const SizedBox(height: 12),
            _DamageResultSummary(prediction: prediction),
            if (prediction.costEstimation?.hasEstimation == true) ...[
              const SizedBox(height: 8),
              _CostEstimationCard(estimation: prediction.costEstimation!),
            ],
          ],

          // error ken mawjoud
          if (state.error != null) ...[
            const SizedBox(height: 12),
            _DamageError(message: state.error!),
          ],
        ],
      ),
    );
  }
}

// buttons camera w upload, responsive حسب width
class _DamagePhotoActions extends StatelessWidget {
  const _DamagePhotoActions({
    required this.isUploading,
    required this.onCamera,
    required this.onGallery,
  });

  // ken width sghir, buttons ywaliw stacked
  static const double _stackedBreakpoint = 360;

  // true waqt upload/analyse
  final bool isUploading;

  // action camera
  final VoidCallback onCamera;

  // action gallery
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    // camera button
    final cameraButton = AppButton(
      label: 'Prendre une photo',
      icon: Icons.photo_camera_outlined,
      onPressed: isUploading ? null : onCamera,
    );

    final uploadButton = AppButton(
      label: 'Importer',
      icon: Icons.photo_library_outlined,
      variant: AppButtonVariant.secondary,
      onPressed: isUploading ? null : onGallery,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // ken espace sghir, nwarriw buttons vertical
        if (constraints.maxWidth < _stackedBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [cameraButton, const SizedBox(height: 10), uploadButton],
          );
        }

        // sinon nwarriw buttons horizontal
        return Row(
          children: [
            Expanded(child: cameraButton),
            const SizedBox(width: 10),
            Expanded(child: uploadButton),
          ],
        );
      },
    );
  }
}

// preview mte3 selected image wala annotated image
class _DamageImagePreview extends StatelessWidget {
  const _DamageImagePreview({required this.state, required this.slot});

  // state mte3 photo
  final _DamagePhotoState state;

  // slot mte3 photo
  final _DamagePhotoSlot slot;

  @override
  Widget build(BuildContext context) {
    // annotated image URL jeya mel API
    final annotatedUrl = state.prediction?.annotatedImageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ken fama annotated URL, nwarriw result image men network
            if (annotatedUrl != null)
              Image.network(
                annotatedUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _ImageLoadingPlaceholder(localFile: state.localFile);
                },
                errorBuilder: (context, error, stackTrace) {
                  return _ImageFallback(
                    localFile: state.localFile,
                    message: 'Résultat annoté indisponible',
                  );
                },
              )

            // ken fama local image bark, nwarriwha
            else if (state.localFile != null)
              Image.file(state.localFile!, fit: BoxFit.cover)

            // sinon placeholder
            else
              _EmptyDamagePhoto(slot: slot),

            // overlay waqt analyzing
            if (state.isUploading)
              Container(
                color: Colors.black.withValues(alpha: 0.48),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 14),
                    Text(
                      'Analyse IA en cours...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// loading placeholder waqt image network loading
class _ImageLoadingPlaceholder extends StatelessWidget {
  const _ImageLoadingPlaceholder({required this.localFile});

  // local image backup
  final File? localFile;

  @override
  Widget build(BuildContext context) {
    // ken fama local image, nwarriwha m3a loading overlay
    if (localFile != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(localFile!, fit: BoxFit.cover),
          Container(
            color: Colors.white.withValues(alpha: 0.60),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    // sinon loading simple
    return const Center(child: CircularProgressIndicator());
  }
}

// fallback ken annotated image ma tloadich
class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.localFile, required this.message});

  // local image backup
  final File? localFile;

  // fallback message
  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // nwarriw local image ken mawjoud
        if (localFile != null)
          Image.file(localFile!, fit: BoxFit.cover)
        else
          Container(color: AppColors.background),

        // message overlay
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.black.withValues(alpha: 0.58),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

// placeholder ken ma famech image selected
class _EmptyDamagePhoto extends StatelessWidget {
  const _EmptyDamagePhoto({required this.slot});

  // slot mte3 photo
  final _DamagePhotoSlot slot;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // slot icon
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(slot.icon, size: 30, color: AppColors.trustBlue),
          ),
          const SizedBox(height: 14),

          Text(
            'Ajoutez des photos des dégâts',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            'Prenez une photo ou importez depuis la galerie.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// pill ywarri status mte3 photo slot
class _DamageStatusPill extends StatelessWidget {
  const _DamageStatusPill({required this.state});

  // state mte3 photo
  final _DamagePhotoState state;

  @override
  Widget build(BuildContext context) {
    // label w color حسب state
    final (label, color) = _status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }

  // t7دد status label w color
  (String, Color) get _status {
    if (state.isUploading) return ('Analyse en cours', AppColors.trustBlue);
    if (state.error != null) return ('Erreur', AppColors.error);
    final prediction = state.prediction;
    if (prediction == null) return ('Non analysé', AppColors.textSecondary);
    return ('Analyse terminée', AppColors.success);
  }
}

// summary mte3 damage prediction
class _DamageResultSummary extends StatelessWidget {
  const _DamageResultSummary({required this.prediction});

  // prediction jeya mel damage API
  final DamagePrediction prediction;

  @override
  Widget build(BuildContext context) {
    // detections mte3 primary result
    final detections = prediction.primaryResult?.detections ?? const [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  prediction.damageDetected
                      ? Icons.auto_awesome_outlined
                      : Icons.verified_outlined,
                  size: 18,
                  color: prediction.damageDetected
                      ? AppColors.trustBlue
                      : AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analyse IA des dégâts',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prediction.damageDetected
                          ? '${prediction.totalDetections} dégât(s) détecté(s)'
                          : 'Aucun dégât visible détecté',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _SoftChip(
                label: 'Analyse terminée',
                color: prediction.damageDetected
                    ? AppColors.warning
                    : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            prediction.summary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),

          if (prediction.bestConfidence != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SoftChip(
                  label:
                      'Confiance ${prediction.bestConfidence!.toStringAsFixed(1)}%',
                  color: AppColors.trustBlue,
                ),
                _SoftChip(
                  label: 'Sévérité ${_severityLabel(prediction)}',
                  color: _severityColor(prediction),
                ),
              ],
            ),
          ],

          if (detections.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Dégâts détectés',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: detections
                  .map((detection) => _DetectionChip(detection: detection))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _severityLabel(DamagePrediction prediction) {
  final confidence = prediction.bestConfidence ?? prediction.confidence;
  if (prediction.totalDetections >= 3 || confidence >= 85) return 'élevée';
  if (prediction.totalDetections >= 2 || confidence >= 60) return 'moyenne';
  return 'faible';
}

Color _severityColor(DamagePrediction prediction) {
  return switch (_severityLabel(prediction)) {
    'élevée' => AppColors.error,
    'moyenne' => AppColors.warning,
    _ => AppColors.success,
  };
}

// chip ywarri detection class w confidence
class _DetectionChip extends StatelessWidget {
  const _DetectionChip({required this.detection});

  // detection wa7da
  final DamageDetection detection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.26)),
      ),
      child: Text(
        '${detection.displayName} · ${detection.confidencePercent.toStringAsFixed(1)}%',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// error UI mte3 damage API
class _DamageError extends StatelessWidget {
  const _DamageError({required this.message});

  // error message
  final String message;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorColor.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // error icon
          Icon(Icons.error_outline_rounded, color: errorColor, size: 18),
          const SizedBox(width: 8),

          // error text
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

// testخرج evidence note men notes existing
String _extractEvidenceNote(String notes) {
  const marker = 'Evidence note:';
  final index = notes.indexOf(marker);
  if (index == -1) return '';

  return notes.substring(index + marker.length).trim();
}

// card twarri cost estimation jeya mel backend
class _CostEstimationCard extends StatelessWidget {
  const _CostEstimationCard({required this.estimation});

  final CostEstimation estimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Estimation des réparations',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          // recommended total + level
          if (estimation.recommendedTotal != null) ...[
            const SizedBox(height: 12),
            Text(
              '${estimation.recommendedTotal!.toStringAsFixed(0)} TND',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (estimation.recommendedLevel != null) ...[
              const SizedBox(height: 8),
              _SoftChip(
                label: 'Niveau ${estimation.recommendedLevel!}',
                color: AppColors.success,
              ),
            ],
          ],

          if (estimation.options.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: estimation.options.entries.map((entry) {
                return _CostOptionChip(
                  label: _capitalizeFirst(entry.key),
                  value: '${entry.value.toStringAsFixed(0)} TND',
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),
          Text(
            'Estimation indicative à confirmer par un expert.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          // data source
          if (estimation.dataSource != null) ...[
            const SizedBox(height: 6),
            Text(
              'Source: ${estimation.dataSource}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],

          // vehicle make / model / year
          if (estimation.vehicleMake != null ||
              estimation.vehicleModel != null ||
              estimation.vehicleYear != null) ...[
            const SizedBox(height: 4),
            Text(
              [
                estimation.vehicleMake,
                estimation.vehicleModel,
                estimation.vehicleYear?.toString(),
              ].whereType<String>().join(' '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],

          // warnings
          if (estimation.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...estimation.warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        w,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CostOptionChip extends StatelessWidget {
  const _CostOptionChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String _capitalizeFirst(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
