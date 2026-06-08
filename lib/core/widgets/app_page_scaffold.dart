import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';

class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.showBackButton = true,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // When showBackButton=false, suppress everything; when true, let the
        // Builder inspect GoRouter's stack and only show the button if we can
        // actually navigate back (canPop). automaticallyImplyLeading is false
        // because we provide our own leading.
        automaticallyImplyLeading: false,
        leading: showBackButton
            ? Builder(
                builder: (ctx) {
                  if (!ctx.canPop()) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    tooltip: 'Retour',
                    onPressed: ctx.pop,
                  );
                },
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            if (subtitle != null)
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: actions,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: body,
        ),
      ),
    );
  }
}
