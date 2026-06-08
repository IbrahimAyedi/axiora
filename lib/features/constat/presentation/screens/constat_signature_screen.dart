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

// screen mte3 signature step
// user ya3mel confirmation 9bal final submit mte3 constat
class ConstatSignatureScreen extends ConsumerStatefulWidget {
  const ConstatSignatureScreen({super.key});

  @override
  ConsumerState<ConstatSignatureScreen> createState() =>
      _ConstatSignatureScreenState();
}

class _ConstatSignatureScreenState
    extends ConsumerState<ConstatSignatureScreen> {
  // key mte3 form bech nvalidiw signer name
  final _formKey = GlobalKey<FormState>();

  // controller mte3 signer name
  late final TextEditingController _signerNameController;

  // true ken user confirmi eli informations s7a7
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();

    // njibou current user men session
    final session = ref.read(appSessionProvider);

    // n3abbiw signer name b full name mte3 current user ken mawjoud
    _signerNameController = TextEditingController(
      text: session.currentUser.fullName ?? '',
    );
  }

  @override
  void dispose() {
    // nfas5ou controller bech ma ysirch memory leak
    _signerNameController.dispose();
    super.dispose();
  }

  // function mte3 final submit
  void _submit() {
    // ken form ghalet wala user ma confirmach, nوقفou
    if (!_formKey.currentState!.validate() || !_confirmed) return;

    // Validate insurance number before submitting
    // nverifiw insurance number mte3 Party A 9bal submit
    final session = ref.read(appSessionProvider);
    final insuranceNumber =
        (session.activeConstat?.partyAInsuranceSnapshot?['insuranceNumber']
            as String?) ??
        (session.activeConstat?.insuranceSnapshot?['insuranceNumber']
            as String?);

    // ken insurance number feragh, nwarriw error w ma nsubmitiwch
    if (insuranceNumber == null || insuranceNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Insurance number is required. Please go back and complete insurance information.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // nsajlou signature confirmation fi draft
    final notifier = ref.read(appSessionProvider.notifier);
    notifier.saveSignatureDraft(
      signerName: _signerNameController.text.trim(),
      confirmed: _confirmed,
    );

    // nsubmitiw constat
    notifier.submitConstat();

    // nemchiw lel success screen
    context.push(RouteNames.constatSuccessPath);
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      // title mte3 page
      title: 'Signature step',

      // subtitle mte3 page
      subtitle: 'Step 7 of 8',

      // body mte3 page
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // hero card mte3 signature step
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF5EA), Color(0xFFFFFCF7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // signature icon
                  const Icon(Icons.draw_outlined, size: 40),
                  const SizedBox(height: 20),

                  // title
                  Text(
                    'Signature step',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),

                  // description
                  Text(
                    'This lightweight confirmation step records who is submitting the draft and whether they confirm the information is correct.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // section mte3 signer details
            SectionCard(
              title: 'Signer details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // signer name input
                  AppTextInput(
                    label: 'Signer name',
                    controller: _signerNameController,
                    validator: (value) =>
                        Validators.requiredField(value, label: 'Signer name'),
                  ),
                  const SizedBox(height: 12),

                  // checkbox confirmation
                  CheckboxListTile(
                    value: _confirmed,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'I confirm that the information provided is correct',
                    ),
                    onChanged: (value) {
                      // nupdatew confirmation state
                      setState(() {
                        _confirmed = value ?? false;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // section mte3 next action
            SectionCard(
              title: 'Next action',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // final submit button
                  AppButton(
                    label: 'Finish declaration',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 12),

                  // back lel review screen
                  AppButton(
                    label: 'Back to review',
                    icon: Icons.arrow_back_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.push(RouteNames.constatReviewPath),
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
