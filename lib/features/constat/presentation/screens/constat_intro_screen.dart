import 'package:flutter/material.dart';

import '../../../../app/router/route_names.dart';
import '../widgets/constat_flow_screen.dart';

// screen d'intro mte3 constat flow
// ywarri introduction 9bal ma user yebda accident report
class ConstatIntroScreen extends StatelessWidget {
  const ConstatIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConstatFlowScreen(
      // title mte3 screen
      title: 'Constat en ligne',

      // subtitle mte3 screen
      subtitle: 'Guided accident declaration',

      // icon mte3 intro
      icon: Icons.assignment_outlined,

      // description tفسر chnowa bech ya3mel user
      description:
          'Start a structured accident report with the parties, vehicles, damages, and final confirmation steps already mapped in the mobile flow.',

      // checklist mte3 steps eli user bech yet3ada bihom
      checklist: [
        'Confirm the incident basics before entering party details.',
        'Move through driver and vehicle information in sequence.',
        'Finish with photos, review, and signature confirmation.',
      ],

      // text mte3 primary button
      primaryLabel: 'Begin accident report',

      // route eli yemchi leha ki user yenzel primary button
      primaryRoute: RouteNames.accidentInfoPath,

      // nawwriw back button bech user yrja3 lel home ken yji men push
      showBackButton: true,
    );
  }
}
