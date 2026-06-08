import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/document_scan.dart';
import '../../data/models/damage_prediction.dart';

/// Read-only cost estimation summary derived from damage photo scans.
///
/// Iterates [photoScans], parses any stored cost estimation from each scan's
/// extractedData, and renders a compact card per slot. Returns
/// [SizedBox.shrink] silently when no scan carries valid cost data.
class CostEstimationSummary extends StatelessWidget {
  const CostEstimationSummary({super.key, required this.photoScans});

  final List<DocumentScan> photoScans;

  /// True when at least one scan in [scans] has parseable cost data.
  static bool hasData(List<DocumentScan> scans) {
    return scans.any(
      (s) =>
          _parseCostEstimation(s.extractedData?['costEstimation']) != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = <_CostEntry>[];

    for (final scan in photoScans) {
      final est = _parseCostEstimation(scan.extractedData?['costEstimation']);
      if (est != null) {
        final label =
            scan.extractedData?['label'] as String? ?? scan.scanType.value;
        entries.add(_CostEntry(label: label, estimation: est));
      }
    }

    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _CostBlock(
            label: entries.length > 1 ? entries[i].label : null,
            estimation: entries[i].estimation,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Internal data holder
// ---------------------------------------------------------------------------

class _CostEntry {
  const _CostEntry({required this.label, required this.estimation});
  final String label;
  final CostEstimation estimation;
}

// ---------------------------------------------------------------------------
// Block widget — renders one CostEstimation
// ---------------------------------------------------------------------------

class _CostBlock extends StatelessWidget {
  const _CostBlock({required this.estimation, this.label});

  final String? label;
  final CostEstimation estimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const green = AppColors.success;
    const bgGreen = AppColors.successLight;
    const borderGreen = Color(0xFFBBF7D0);

    final vehicleText = [
      estimation.vehicleMake,
      estimation.vehicleModel,
      estimation.vehicleYear?.toString(),
    ].whereType<String>().join(' ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // optional slot label shown when multiple slots have estimates
          if (label != null) ...[
            Text(
              label!,
              style: theme.textTheme.labelMedium?.copyWith(color: green),
            ),
            const SizedBox(height: 6),
          ],

          // recommended total + level pill
          if (estimation.recommendedTotal != null)
            Row(
              children: [
                const Icon(
                  Icons.monetization_on_outlined,
                  size: 16,
                  color: green,
                ),
                const SizedBox(width: 6),
                Text(
                  '${estimation.recommendedTotal!.toStringAsFixed(0)} TND',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
                if (estimation.recommendedLevel != null) ...[
                  const SizedBox(width: 8),
                  _Pill(label: estimation.recommendedLevel!),
                ],
              ],
            ),

          // bas / moyenne / haut tier options
          if (estimation.options.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: estimation.options.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderGreen),
                  ),
                  child: Text(
                    '${_cap(e.key)}: ${e.value.toStringAsFixed(0)} TND',
                    style: theme.textTheme.labelSmall,
                  ),
                );
              }).toList(),
            ),
          ],

          // vehicle make / model / year
          if (vehicleText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              vehicleText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],

          // data source label
          if (estimation.dataSource != null) ...[
            const SizedBox(height: 4),
            Text(
              'Source: ${estimation.dataSource}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],

          // backend warnings
          if (estimation.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final w in estimation.warnings)
              Padding(
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
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small level badge pill
// ---------------------------------------------------------------------------

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Parsing — reads camelCase keys written by CostEstimation.toJson()
//
// CostEstimation.fromJson() expects backend snake_case keys. The stored data
// in DocumentScan.extractedData uses camelCase from toJson(), so we parse
// the stored map directly without going through fromJson().
// ---------------------------------------------------------------------------

CostEstimation? _parseCostEstimation(Object? raw) {
  if (raw is! Map) return null;
  try {
    final json = Map<String, dynamic>.from(raw);

    final recommendedTotal = _toDouble(json['recommendedTotal']);
    final recommendedLevel = json['recommendedLevel'] as String?;

    final options = <String, double>{};
    final rawOptions = json['options'];
    if (rawOptions is Map) {
      rawOptions.forEach((key, val) {
        final d = _toDouble(val);
        if (d != null && d > 0) options[key.toString()] = d;
      });
    }

    final rawWarnings = json['warnings'];
    final warnings = rawWarnings is List
        ? rawWarnings.whereType<String>().toList()
        : <String>[];

    final vehicleMake = json['vehicleMake'] as String?;
    final vehicleModel = json['vehicleModel'] as String?;
    final rawYear = json['vehicleYear'];
    final vehicleYear = rawYear is num ? rawYear.toInt() : null;
    final dataSource = json['dataSource'] as String?;

    final est = CostEstimation(
      recommendedTotal: recommendedTotal,
      recommendedLevel: recommendedLevel,
      options: Map.unmodifiable(options),
      dataSource: dataSource,
      warnings: List.unmodifiable(warnings),
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      vehicleYear: vehicleYear,
    );

    return est.hasEstimation ? est : null;
  } catch (_) {
    return null;
  }
}

double? _toDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String _cap(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
