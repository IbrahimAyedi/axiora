import 'package:flutter/material.dart';

import '../../../../core/models/document_scan.dart';
import '../../data/models/damage_prediction.dart';

const _summaryBorder = Color(0xFFD8E2EE);
const _summaryBackground = Color(0xFFF4F7FB);
const _summaryNavy = Color(0xFF123A63);
const _summaryGreen = Color(0xFF1F8A5B);
const _summaryMuted = Color(0xFF627387);
const _summaryWarning = Color(0xFFB7791F);

/// Read-only cost estimation summary derived from damage photo scans.
class CostEstimationSummary extends StatelessWidget {
  const CostEstimationSummary({super.key, required this.photoScans});

  final List<DocumentScan> photoScans;

  static bool hasData(List<DocumentScan> scans) {
    return scans.any(
      (scan) =>
          _parseCostEstimation(scan.extractedData?['costEstimation']) != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = <_CostEntry>[];

    for (final scan in photoScans) {
      final estimation = _parseCostEstimation(
        scan.extractedData?['costEstimation'],
      );
      if (estimation != null) {
        final label =
            scan.extractedData?['label'] as String? ?? scan.scanType.value;
        entries.add(_CostEntry(label: label, estimation: estimation));
      }
    }

    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
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

class _CostEntry {
  const _CostEntry({required this.label, required this.estimation});

  final String label;
  final CostEstimation estimation;
}

class _CostBlock extends StatelessWidget {
  const _CostBlock({required this.estimation, this.label});

  final String? label;
  final CostEstimation estimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicleText = [
      estimation.vehicleMake,
      estimation.vehicleModel,
      estimation.vehicleYear?.toString(),
    ].whereType<String>().join(' ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _summaryBorder),
        boxShadow: [
          BoxShadow(
            color: _summaryNavy.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  size: 20,
                  color: _summaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimation des réparations',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: _summaryNavy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (label != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        label!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _summaryMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (estimation.recommendedLevel != null)
                _Pill(label: 'Niveau ${estimation.recommendedLevel!}'),
            ],
          ),
          if (estimation.recommendedTotal != null) ...[
            const SizedBox(height: 14),
            Text(
              '${estimation.recommendedTotal!.toStringAsFixed(0)} TND',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: _summaryGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
          if (estimation.options.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: estimation.options.entries.map((entry) {
                return _CostOption(
                  label: _cap(entry.key),
                  value: '${entry.value.toStringAsFixed(0)} TND',
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Estimation indicative à confirmer par un expert.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _summaryMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (vehicleText.isNotEmpty || estimation.dataSource != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (vehicleText.isNotEmpty)
                  _MetaChip(
                    icon: Icons.directions_car_outlined,
                    label: vehicleText,
                  ),
                if (estimation.dataSource != null)
                  _MetaChip(
                    icon: Icons.dataset_outlined,
                    label: 'Source: ${estimation.dataSource}',
                  ),
              ],
            ),
          ],
          if (estimation.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final warning in estimation.warnings)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: _summaryWarning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        warning,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _summaryWarning,
                          fontWeight: FontWeight.w600,
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

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _summaryGreen.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _summaryGreen,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CostOption extends StatelessWidget {
  const _CostOption({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _summaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _summaryBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: _summaryMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: _summaryNavy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F1FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _summaryBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _summaryNavy),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _summaryNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

CostEstimation? _parseCostEstimation(Object? raw) {
  if (raw is! Map) return null;
  try {
    final json = Map<String, dynamic>.from(raw);

    final recommendedTotal = _toDouble(json['recommendedTotal']);
    final recommendedLevel = json['recommendedLevel'] as String?;

    final options = <String, double>{};
    final rawOptions = json['options'];
    if (rawOptions is Map) {
      rawOptions.forEach((key, value) {
        final parsed = _toDouble(value);
        if (parsed != null && parsed > 0) {
          options[key.toString()] = parsed;
        }
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

    final estimation = CostEstimation(
      recommendedTotal: recommendedTotal,
      recommendedLevel: recommendedLevel,
      options: Map.unmodifiable(options),
      dataSource: dataSource,
      warnings: List.unmodifiable(warnings),
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      vehicleYear: vehicleYear,
    );

    return estimation.hasEstimation ? estimation : null;
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
