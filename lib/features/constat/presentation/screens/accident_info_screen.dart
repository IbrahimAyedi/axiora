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
      // title mte3 page
      title: 'Accident details',

      // subtitle mte3 page
      subtitle: 'Step 2 of 8',

      // body mte3 page
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
                    'Accident details',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // subtitle
                  Text(
                    'Capture the key circumstances of the incident.',
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
              title: 'Date and time',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // button y7el date/time picker
                  OutlinedButton.icon(
                    onPressed: _selectDateTime,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedDateTime == null
                          ? 'Select date and time'
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

            // section mte3 accident location
            SectionCard(
              title: 'Location',
              child: TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Tunis - City Center',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  // location obligatoire
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the accident location';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // section mte3 accident description + entity extraction
            SectionCard(
              title: 'Description',
              subtitle: 'Describe what happened',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // description input
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText:
                          'e.g., Accident le 08/05/2026 à Sfax. Témoin Ali 22333444.',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      // description obligatoire
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the accident description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // button ybda ML Kit entity extraction
                  AppButton(
                    label: _isAnalyzing ? 'Analyzing...' : 'Analyze details',
                    icon: Icons.auto_awesome,
                    variant: AppButtonVariant.secondary,
                    onPressed: _isAnalyzing ? null : _analyzeDetails,
                  ),

                  // ken fama extracted entities, nwarriwhom fi chips
                  if (_extractedEntities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Detected details:',
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
              title: 'Additional notes',
              subtitle: 'Optional',
              child: TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Weather was clear, traffic was moderate',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 16),

            // section mte3 next action
            SectionCard(
              title: 'Next action',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // save w continue
                  AppButton(
                    label: 'Continue to driver details',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _saveAndContinue,
                  ),
                  const SizedBox(height: 12),

                  // back lel intro
                  AppButton(
                    label: 'Back to intro',
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
