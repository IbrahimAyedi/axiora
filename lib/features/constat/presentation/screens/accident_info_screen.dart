import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/services/entity_extraction_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';

// screen mte3 accident information
// user y3abi date, location, description w notes mte3 accident
class AccidentInfoScreen extends ConsumerStatefulWidget {
  const AccidentInfoScreen({super.key});

  @override
  ConsumerState<AccidentInfoScreen> createState() => _AccidentInfoScreenState();
}

class _AccidentInfoScreenState extends ConsumerState<AccidentInfoScreen> {
  // key mte3 form bech nvalidiw inputs
  final _formKey = GlobalKey<FormState>();

  // controllers mte3 fields
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  // date w time mte3 accident
  DateTime? _selectedDateTime;

  // entities extracted mel accident description
  List<Map<String, dynamic>> _extractedEntities = [];

  // true waqt entity extraction yekhdem
  bool _isAnalyzing = false;

  // service mte3 ML Kit Entity Extraction
  final _entityService = EntityExtractionService();

  // focus node bech "Modifier manuellement" yfocus location field
  final _locationFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // ninitializiw entity extraction service
    _entityService.initialize();

    // Load existing data if available
    // ken fama active constat fih data 9dima, n3abbiw bih form
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final constat = ref.read(appSessionProvider).activeConstat;
      if (constat != null) {
        _selectedDateTime = constat.accidentDateTime;
        _locationController.text = constat.accidentLocation ?? '';
        _descriptionController.text = constat.accidentDescription ?? '';
        _notesController.text = constat.notes ?? '';
        _extractedEntities = constat.extractedEntities ?? [];
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // nfas5ou controllers bech ma ysirch memory leak
    _locationController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();

    // nsakrou entity service
    _entityService.dispose();
    _locationFocusNode.dispose();

    super.dispose();
  }

  // function t5alli user ya5tar date w time mte3 accident
  Future<void> _selectDateTime() async {
    // n7ellou date picker
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    // ken user cancel, nوقفou
    if (date == null || !mounted) return;

    // n7ellou time picker
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
    );

    // ken user cancel, nوقفou
    if (time == null || !mounted) return;

    // nركبو date + time fi DateTime wa7da
    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  // t7allel description w تستخرج details kif date, phone, address...
  Future<void> _analyzeDetails() async {
    final description = _descriptionController.text.trim();

    // ken description fergha, nwarriw warning
    if (description.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter accident details first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // nbadlou state l analyzing
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // ML Kit Entity Extraction yestخرج entities mel text
      final entities = await _entityService.extractEntities(description);

      if (!mounted) return;

      // nwarriw result lel user
      if (entities.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No key details detected.'),
            backgroundColor: Colors.grey,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detected ${entities.length} key detail(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // nsajlou extracted entities fi state
      setState(() {
        _extractedEntities = entities;
      });
    } catch (e) {
      // ken analysis tfشل
      debugPrint('Error analyzing details: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not analyze details. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // nرجعou analyzing false
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  // tsajel accident details w temchi lel driver info step
  void _saveAndContinue() {
    // nvalidiw form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // nsajlou data fi app session active constat
    final notifier = ref.read(appSessionProvider.notifier);
    notifier.saveAccidentDetails(
      dateTime: _selectedDateTime,
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      notes: _notesController.text.trim(),
      extractedEntities: _extractedEntities.isEmpty ? null : _extractedEntities,
    );

    // nemchiw lel driver info screen
    context.push(RouteNames.driverInfoPath);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // true ken app fi dark mode
    final isDark = theme.brightness == Brightness.dark;

    return AppPageScaffold(
      title: 'Informations accident',
      subtitle: 'Informations accident',
      currentStep: 2,
      totalSteps: 8,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // hero card mte3 accident step
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
                  // warning icon
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 40,
                    color: isDark
                        ? Colors.orange.shade300
                        : Colors.orange.shade700,
                  ),
                  const SizedBox(height: 20),

                  // title
                  Text(
                    'Informations accident',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'Renseignez les circonstances de l\'accident : date, lieu et description.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // section mte3 date w time
            SectionCard(
              title: 'Date et heure',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // button y7el date/time picker
                  OutlinedButton.icon(
                    onPressed: _selectDateTime,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedDateTime == null
                          ? 'Sélectionner la date et l\'heure'
                          : DateFormat(
                              'yyyy-MM-dd HH:mm',
                            ).format(_selectedDateTime!),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // section mte3 accident location — premium map card
            SectionCard(
              title: 'Lieu',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _locationController,
                    focusNode: _locationFocusNode,
                    decoration: const InputDecoration(
                      hintText: 'ex. Tunis - Centre-ville',
                      prefixIcon: Icon(Icons.edit_location_alt_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez saisir le lieu de l\'accident';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _locationController,
                    builder: (context, value, _) {
                      return _LocationMapPreview(
                        location: value.text.trim(),
                        onGpsPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'La localisation GPS sera disponible prochainement.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        onManualPressed: () =>
                            _locationFocusNode.requestFocus(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // section mte3 accident description + entity extraction
            SectionCard(
              title: 'Description',
              subtitle: 'Décrivez ce qui s\'est passé',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText:
                          'ex. Accident le 08/05/2026 à Sfax. Témoin Ali 22333444.',
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez saisir la description de l\'accident';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // button ybda ML Kit entity extraction
                  AppButton(
                    label: _isAnalyzing ? 'Analyse en cours...' : 'Analyser les détails',
                    icon: Icons.auto_awesome,
                    variant: AppButtonVariant.secondary,
                    onPressed: _isAnalyzing ? null : _analyzeDetails,
                  ),

                  // ken fama extracted entities, nwarriwhom fi chips
                  if (_extractedEntities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Détails détectés :',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _extractedEntities.map((entity) {
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

            // section mte3 additional notes
            SectionCard(
              title: 'Notes complémentaires',
              subtitle: 'Optionnel',
              child: TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'ex. Météo dégagée, circulation modérée',
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 16),

            // section mte3 next action
            SectionCard(
              title: 'Actions',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    label: 'Continuer vers le conducteur',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _saveAndContinue,
                  ),
                  const SizedBox(height: 12),

                  AppButton(
                    label: 'Retour à l\'introduction',
                    icon: Icons.arrow_back_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.push(RouteNames.constatIntroPath),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
}

// ── Premium fake-map location preview ────────────────────────────────────────

class _LocationMapPreview extends StatelessWidget {
  const _LocationMapPreview({
    required this.location,
    required this.onGpsPressed,
    required this.onManualPressed,
  });

  final String location;
  final VoidCallback onGpsPressed;
  final VoidCallback onManualPressed;

  bool get _hasLocation => location.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          // ── Map area ──────────────────────────────────────────────────
          SizedBox(
            height: 148,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFDCEEFB), Color(0xFFC8E0F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

                // Grid + road lines
                const CustomPaint(painter: _MapGridPainter()),

                // Centre: pin + label
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pin halo
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _hasLocation
                            ? const Color(0xFF1769AA).withValues(alpha: 0.14)
                            : const Color(0xFF6B7280).withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 30,
                        color: _hasLocation
                            ? const Color(0xFF1769AA)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // "Position de l'accident" label
                    Text(
                      'Position de l\'accident',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _hasLocation
                            ? const Color(0xFF0B2D4D)
                            : const Color(0xFF9CA3AF),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Location pill
                    Container(
                      constraints: const BoxConstraints(maxWidth: 230),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _hasLocation
                            ? Colors.white.withValues(alpha: 0.88)
                            : Colors.white.withValues(alpha: 0.60),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _hasLocation
                              ? const Color(0xFF1769AA).withValues(alpha: 0.18)
                              : const Color(0xFFD8E2EE),
                        ),
                      ),
                      child: Text(
                        _hasLocation ? location : 'Aucune position renseignée',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: _hasLocation
                              ? const Color(0xFF0B2D4D)
                              : const Color(0xFF9CA3AF),
                          fontWeight: _hasLocation
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Top-right: "Carte" badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.84),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF1769AA).withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.layers_outlined,
                          size: 11,
                          color: const Color(0xFF1769AA).withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Carte',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1769AA).withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top-left: status pill (only when location is set)
                if (_hasLocation)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E7D32),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Renseigné',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Action strip ──────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF4F7FB),
              border: Border(
                top: BorderSide(color: Color(0xFFD8E2EE)),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _MapActionButton(
                      icon: Icons.my_location_rounded,
                      label: 'Utiliser ma position',
                      color: const Color(0xFF1769AA),
                      onTap: onGpsPressed,
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Color(0xFFD8E2EE),
                  ),
                  Expanded(
                    child: _MapActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Modifier manuellement',
                      color: const Color(0xFF0B2D4D),
                      onTap: onManualPressed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single action button in the strip ────────────────────────────────────────

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Map grid painter ──────────────────────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1769AA).withValues(alpha: 0.07)
      ..strokeWidth = 1.0;

    const step = 26.0;
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Thicker "road" lines simulating streets
    final roadPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.22)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height * 0.44),
      Offset(size.width, size.height * 0.44),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.36, 0),
      Offset(size.width * 0.36, size.height),
      roadPaint,
    );

    // Secondary thinner road
    final roadPaint2 = Paint()
      ..color = const Color(0xFF1769AA).withValues(alpha: 0.10)
      ..strokeWidth = 1.8;
    canvas.drawLine(
      Offset(0, size.height * 0.70),
      Offset(size.width, size.height * 0.70),
      roadPaint2,
    );
    canvas.drawLine(
      Offset(size.width * 0.65, 0),
      Offset(size.width * 0.65, size.height),
      roadPaint2,
    );
  }

  @override
  bool shouldRepaint(_MapGridPainter oldDelegate) => false;
}
