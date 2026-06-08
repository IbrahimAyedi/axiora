import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/app_text_input.dart';
import '../../../../core/widgets/section_card.dart';

// TODO(cleanup): CarteGriseAutofillScreen is a DUPLICATE of CarteGriseResultScreen.
// Both show the same five editable fields (plate, owner, brand, model, VIN)
// and call updateCarteGriseDraft().  The autofill screen is the third review
// step in the cart-grise flow (scan → result → autofill → vehicleInfo) and is
// safe to remove in a future refactor by changing CarteGriseResultScreen to
// navigate directly to RouteNames.vehicleInfoPath instead of
// RouteNames.carteGriseAutofillPath.
// Do NOT delete this file until that navigation change is made and tested.
class CarteGriseAutofillScreen extends ConsumerStatefulWidget {
  const CarteGriseAutofillScreen({super.key});

  @override
  ConsumerState<CarteGriseAutofillScreen> createState() =>
      _CarteGriseAutofillScreenState();
}

class _CarteGriseAutofillScreenState
    extends ConsumerState<CarteGriseAutofillScreen> {
  // key mte3 form bech nvalidiw inputs
  final _formKey = GlobalKey<FormState>();

  // controllers mte3 fields eli jeyin mel OCR
  late final TextEditingController _plateController;
  late final TextEditingController _ownerController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _vinController;

  @override
  void initState() {
    super.initState();

    // njibou extracted data mel active scan
    final scanData = ref.read(appSessionProvider).activeScan?.extractedData;

    // n3abbiw fields b data eli OCR 5rajha
    _plateController = TextEditingController(
      text: scanData?['plateNumber'] as String? ?? '',
    );
    _ownerController = TextEditingController(
      text: scanData?['ownerName'] as String? ?? '',
    );
    _brandController = TextEditingController(
      text: scanData?['brand'] as String? ?? '',
    );
    _modelController = TextEditingController(
      text: scanData?['model'] as String? ?? '',
    );
    _vinController = TextEditingController(
      text: scanData?['vin'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    // nfas5ou controllers bech ma ysirch memory leak
    _plateController.dispose();
    _ownerController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _vinController.dispose();
    super.dispose();
  }

  // tsyncy values mte3 form m3a active scan/profile draft
  void _syncDraft() {
    ref
        .read(appSessionProvider.notifier)
        .updateCarteGriseDraft(
          plateNumber: _plateController.text.trim(),
          ownerName: _ownerController.text.trim(),
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          vin: _vinController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      // title mte3 page
      title: 'Autofill vehicle form',

      // subtitle mte3 page
      subtitle: 'Turn OCR output into editable fields',

      // body mte3 page
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // explanation card
            const SectionCard(
              title: 'How this step works',
              subtitle: 'Mobile-only autofill flow',
              child: Text(
                'Review the extracted carte grise fields, correct anything unclear, then inject them into the vehicle step of the constat flow.',
              ),
            ),
            const SizedBox(height: 16),

            // plate number extracted mel OCR
            AppTextInput(
              label: 'Plate number',
              controller: _plateController,
              validator: (value) =>
                  Validators.requiredField(value, label: 'Plate number'),
            ),
            const SizedBox(height: 16),

            // owner/driver name extracted mel OCR
            AppTextInput(
              label: 'Owner / driver name',
              controller: _ownerController,
              validator: (value) =>
                  Validators.requiredField(value, label: 'Owner / driver name'),
            ),
            const SizedBox(height: 16),

            // brand w model fi nafs row
            Row(
              children: [
                Expanded(
                  child: AppTextInput(
                    label: 'Brand',
                    controller: _brandController,
                    validator: (value) =>
                        Validators.requiredField(value, label: 'Brand'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextInput(
                    label: 'Model',
                    controller: _modelController,
                    validator: (value) =>
                        Validators.requiredField(value, label: 'Model'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // VIN extracted mel OCR
            AppTextInput(
              label: 'VIN',
              controller: _vinController,
              validator: (value) =>
                  Validators.requiredField(value, label: 'VIN'),
            ),
            const SizedBox(height: 20),

            // button ysave values w yemchi lel vehicle info step
            AppButton(
              label: 'Use in vehicle form',
              icon: Icons.assignment_turned_in_outlined,
              onPressed: () {
                // nvalidiw form 9bal sync
                if (!_formKey.currentState!.validate()) return;

                // nsyncyw corrected OCR data
                _syncDraft();

                // nemchiw lel vehicle form
                context.push(RouteNames.vehicleInfoPath);
              },
            ),
            const SizedBox(height: 12),

            // button yarja3 lel OCR preview
            AppButton(
              label: 'Back to OCR preview',
              variant: AppButtonVariant.secondary,
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
