// model principal mte3 damage prediction response
class DamagePrediction {
  const DamagePrediction({
    required this.confidence,
    required this.damageDetected,
    required this.detectedImagesCount,
    required this.imagesCount,
    required this.totalDetections,
    required this.results,
    this.requestId,
    this.costEstimation,
  });

  // confidence globale mte3 prediction
  final double confidence;

  // true ken AI detecta damage
  final bool damageDetected;

  // nombre mte3 images eli fihom damage
  final int detectedImagesCount;

  // nombre total mte3 images
  final int imagesCount;

  // nombre total mte3 detections
  final int totalDetections;

  // request id jey mel backend/API
  final String? requestId;

  // results mte3 kol image
  final List<DamagePredictionResult> results;

  // optional cost estimation jeya mel backend
  final CostEstimation? costEstimation;

  // awel result, غالبا image principale
  DamagePredictionResult? get primaryResult {
    if (results.isEmpty) return null;
    return results.first;
  }

  // URL mte3 image annotée b bounding boxes
  String? get annotatedImageUrl => primaryResult?.annotatedImageUrl;

  // akber confidence men detections kol
  double? get bestConfidence {
    final detections = results.expand((result) => result.detections);
    if (detections.isEmpty) return null;

    return detections
        .map((detection) => detection.confidence)
        .reduce((a, b) => a > b ? a : b);
  }

  // summary text yesta3mlouh UI wala scan note
  String get summary {
    final result = primaryResult;
    if (!damageDetected || result == null || result.detections.isEmpty) {
      return 'No visible vehicle damage detected by AI.';
    }

    // nختارو detection eli 3andha highest confidence
    final bestDetection = result.detections.reduce(
      (a, b) => a.confidence >= b.confidence ? a : b,
    );

    // n7awlou class name l readable text
    final label = _humanizeClassName(bestDetection.className);
    final confidence = bestDetection.confidencePercent.toStringAsFixed(1);
    final suffix = totalDetections == 1 ? 'detection' : 'detections';

    return 'Damage detected: $label at $confidence% confidence '
        '($totalDetections $suffix).';
  }

  // t7awel prediction l Map bech nsajlouha fi DocumentScan extractedData
  Map<String, dynamic> toScanData() {
    return {
      'confidence': confidence,
      'damageDetected': damageDetected,
      'detectedImagesCount': detectedImagesCount,
      'imagesCount': imagesCount,
      'requestId': requestId,
      'totalDetections': totalDetections,
      'annotatedImageUrl': annotatedImageUrl,
      'summary': summary,
      'results': results.map((result) => result.toJson()).toList(),
      if (costEstimation != null) 'costEstimation': costEstimation!.toJson(),
    };
  }

  // t7awel response jeya mel damage API l DamagePrediction
  factory DamagePrediction.fromJson(
    Map<String, dynamic> json, {
    required Uri endpoint,
  }) {
    // nparsew results list
    final resultsJson = json['results'];
    final results = resultsJson is List
        ? resultsJson
              .whereType<Map>()
              .map(
                (item) => DamagePredictionResult.fromJson(
                  Map<String, dynamic>.from(item),
                  endpoint: endpoint,
                ),
              )
              .toList()
        : <DamagePredictionResult>[];

    // parse optional cost_estimation — ignore if missing or malformed
    // backend nests it inside results[index].cost_estimation, not at root level
    CostEstimation? costEstimation;
    try {
      Object? rawCost = json['cost_estimation'];
      if (rawCost == null && resultsJson is List && resultsJson.isNotEmpty) {
        final first = resultsJson.first;
        if (first is Map) rawCost = first['cost_estimation'];
      }
      if (rawCost is Map) {
        costEstimation = CostEstimation.fromJson(
          Map<String, dynamic>.from(rawCost),
        );
      }
    } catch (_) {
      // malformed cost_estimation — keep null, do not crash
    }

    return DamagePrediction(
      confidence: _doubleFromJson(json['conf']),
      damageDetected: json['damage_detected'] as bool? ?? false,
      detectedImagesCount: _intFromJson(json['detected_images_count']),
      imagesCount: _intFromJson(json['images_count']),
      requestId: json['request_id'] as String?,
      totalDetections: _intFromJson(json['total_detections']),
      results: List<DamagePredictionResult>.unmodifiable(results),
      costEstimation: costEstimation,
    );
  }
}

// result mte3 image wa7da fi damage prediction
class DamagePredictionResult {
  const DamagePredictionResult({
    required this.damageDetected,
    required this.detectionsCount,
    required this.detections,
    required this.classesCount,
    required this.bestConfidenceByClass,
    this.annotatedImage,
    this.annotatedImageUrl,
    this.originalImage,
    this.status,
  });

  // true ken image hedhi فيها damage
  final bool damageDetected;

  // nombre detections fi image hedhi
  final int detectionsCount;

  // path/name mte3 annotated image
  final String? annotatedImage;

  // full URL mte3 annotated image
  final String? annotatedImageUrl;

  // original image path/name
  final String? originalImage;

  // status jey mel API
  final String? status;

  // liste mte3 detections fi image
  final List<DamageDetection> detections;

  // count mte3 detections par class
  final Map<String, int> classesCount;

  // best confidence par class
  final Map<String, double> bestConfidenceByClass;

  // t7awel result l Map
  Map<String, dynamic> toJson() {
    return {
      'damageDetected': damageDetected,
      'detectionsCount': detectionsCount,
      'annotatedImage': annotatedImage,
      'annotatedImageUrl': annotatedImageUrl,
      'originalImage': originalImage,
      'status': status,
      'classesCount': classesCount,
      'bestConfidenceByClass': bestConfidenceByClass,
      'detections': detections.map((detection) => detection.toJson()).toList(),
    };
  }

  // t7awel json mte3 result l DamagePredictionResult
  factory DamagePredictionResult.fromJson(
    Map<String, dynamic> json, {
    required Uri endpoint,
  }) {
    // nparsew detections list
    final detectionsJson = json['detections'];
    final detections = detectionsJson is List
        ? detectionsJson
              .whereType<Map>()
              .map(
                (item) =>
                    DamageDetection.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <DamageDetection>[];

    return DamagePredictionResult(
      damageDetected: json['damage_detected'] as bool? ?? false,
      detectionsCount: _intFromJson(json['detections_count']),
      annotatedImage: json['annotated_image'] as String?,
      annotatedImageUrl: _normalizeImageUrl(
        json['annotated_image_url'],
        endpoint,
      ),
      originalImage: json['original_image'] as String?,
      status: json['status'] as String?,
      detections: List<DamageDetection>.unmodifiable(detections),
      classesCount: _intMapFromJson(json['classes_count']),
      bestConfidenceByClass: _doubleMapFromJson(
        json['best_confidence_by_class'],
      ),
    );
  }
}

// detection wa7da: type damage + confidence
class DamageDetection {
  const DamageDetection({
    required this.classId,
    required this.className,
    required this.confidence,
    required this.confidencePercent,
  });

  // id mte3 damage class
  final int classId;

  // class name raw jeya mel model
  final String className;

  // confidence bin 0 w 1
  final double confidence;

  // confidence percentage
  final double confidencePercent;

  // display name readable
  String get displayName => _humanizeClassName(className);

  // t7awel detection l Map
  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'className': className,
      'confidence': confidence,
      'confidencePercent': confidencePercent,
    };
  }

  // t7awel json l DamageDetection
  factory DamageDetection.fromJson(Map<String, dynamic> json) {
    final confidence = _doubleFromJson(json['confidence']);

    return DamageDetection(
      classId: _intFromJson(json['class_id']),
      className: json['class_name'] as String? ?? 'unknown_damage',
      confidence: confidence,
      confidencePercent: _doubleFromJson(
        json['confidence_percent'],
        fallback: confidence * 100,
      ),
    );
  }
}

// t7awel class name men snake_case l readable text
String _humanizeClassName(String value) {
  final words = value
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.trim().isNotEmpty);

  return words
      .map((word) {
        if (word.length == 1) return word.toUpperCase();
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}

// t7awel image URL jeya mel backend l URL valide
// ken backend يرجع localhost, nبدلوه b ngrok/current endpoint host
String? _normalizeImageUrl(Object? rawValue, Uri endpoint) {
  if (rawValue is! String || rawValue.trim().isEmpty) return null;

  final parsed = Uri.tryParse(rawValue.trim());
  if (parsed == null) return rawValue.trim();

  // ken URL relative, nresolveiwha 3la endpoint
  if (!parsed.hasScheme) {
    return endpoint.resolveUri(parsed).toString();
  }

  // ken URL mahech localhost, nرجعوها kif ma hiya
  final isLocalhost =
      parsed.host == '127.0.0.1' ||
      parsed.host == 'localhost' ||
      parsed.host == '0.0.0.0';
  if (!isLocalhost) return parsed.toString();

  // ken backend رجع localhost, nبدلو host b host mte3 endpoint
  return Uri(
    scheme: endpoint.scheme,
    userInfo: endpoint.userInfo,
    host: endpoint.host,
    port: endpoint.hasPort ? endpoint.port : null,
    path: parsed.path,
    query: parsed.query,
    fragment: parsed.fragment,
  ).toString();
}

// t7awel value l int safely
int _intFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

// t7awel value l double safely
double _doubleFromJson(Object? value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

// t7awel json map l Map<String, int>
Map<String, int> _intMapFromJson(Object? value) {
  if (value is! Map) return const <String, int>{};

  return Map<String, int>.unmodifiable(
    value.map((key, value) => MapEntry(key.toString(), _intFromJson(value))),
  );
}

// t7awel json map l Map<String, double>
Map<String, double> _doubleMapFromJson(Object? value) {
  if (value is! Map) return const <String, double>{};

  return Map<String, double>.unmodifiable(
    value.map((key, value) => MapEntry(key.toString(), _doubleFromJson(value))),
  );
}

// extracts the numeric total from a backend option value:
// accepts either a plain number or a map containing a 'total' key
double _extractOptionTotal(Object? value) {
  if (value is Map && value.containsKey('total')) {
    return _doubleFromJson(value['total']);
  }
  return _doubleFromJson(value);
}

// optional cost estimation jeya mel backend /api/predict response
class CostEstimation {
  const CostEstimation({
    this.recommendedTotal,
    this.recommendedLevel,
    this.options = const {},
    this.dataSource,
    this.warnings = const [],
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleYear,
  });

  // recommended repair total in TND (null = not available)
  final double? recommendedTotal;

  // recommended tier: bas / moyenne / haut
  final String? recommendedLevel;

  // all tier totals: {'bas': 800, 'moyenne': 1200, 'haut': 1600}
  final Map<String, double> options;

  // data source label from backend
  final String? dataSource;

  // optional warnings from backend
  final List<String> warnings;

  // vehicle make extracted by backend
  final String? vehicleMake;

  // vehicle model extracted by backend
  final String? vehicleModel;

  // vehicle year extracted by backend
  final int? vehicleYear;

  // true ken fama estimation ta3rad
  bool get hasEstimation => recommendedTotal != null || options.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'recommendedTotal': recommendedTotal,
      'recommendedLevel': recommendedLevel,
      'options': options,
      'dataSource': dataSource,
      'warnings': warnings,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'vehicleYear': vehicleYear,
    };
  }

  factory CostEstimation.fromJson(Map<String, dynamic> json) {
    // backend 'estimations' array format: aggregate totals across all damage items
    final estimationsJson = json['estimations'];
    if (estimationsJson is List && estimationsJson.isNotEmpty) {
      double totalBas = 0, totalMoyenne = 0, totalHaut = 0;
      double totalRecommended = 0;
      String? firstLevel;
      String? firstDataSource;
      final allWarnings = <String>[];

      for (final item in estimationsJson) {
        if (item is! Map) continue;
        final est = Map<String, dynamic>.from(item);

        firstLevel ??= est['recommended_level'] as String?;
        firstDataSource ??= est['data_source'] as String?;

        final rawOpts = est['options'];
        if (rawOpts is Map) {
          totalBas += _extractOptionTotal(rawOpts['bas']);
          totalMoyenne += _extractOptionTotal(rawOpts['moyenne']);
          totalHaut += _extractOptionTotal(rawOpts['haut']);
        }

        final rawRec = est['recommended'];
        if (rawRec is Map) {
          totalRecommended += _doubleFromJson(rawRec['total']);
        }

        final rawW = est['warnings'];
        if (rawW is List) allWarnings.addAll(rawW.whereType<String>());
      }

      // root-level 'warning' string (not a list) also collected
      final rootWarning = json['warning'] as String?;
      if (rootWarning != null && rootWarning.isNotEmpty) {
        allWarnings.add(rootWarning);
      }

      final options = <String, double>{
        if (totalBas > 0) 'bas': totalBas,
        if (totalMoyenne > 0) 'moyenne': totalMoyenne,
        if (totalHaut > 0) 'haut': totalHaut,
      };

      // vehicle at root of cost_estimation object; year may arrive as a string
      String? vehicleMake;
      String? vehicleModel;
      int? vehicleYear;
      final rawVehicle = json['vehicle'];
      if (rawVehicle is Map) {
        vehicleMake = rawVehicle['make'] as String?;
        vehicleModel = rawVehicle['model'] as String?;
        final rawYear = rawVehicle['year'];
        vehicleYear = rawYear is num
            ? rawYear.toInt()
            : (rawYear is String ? int.tryParse(rawYear) : null);
      }

      return CostEstimation(
        recommendedTotal: totalRecommended > 0 ? totalRecommended : null,
        recommendedLevel: firstLevel,
        options: Map.unmodifiable(options),
        dataSource: firstDataSource,
        warnings: List.unmodifiable(allWarnings),
        vehicleMake: vehicleMake,
        vehicleModel: vehicleModel,
        vehicleYear: vehicleYear,
      );
    }

    // flat format — backward compatible with any top-level cost_estimation shape
    String? recommendedLevel = json['recommended_level'] as String?;

    final options = <String, double>{};
    final rawOptions = json['options'];
    if (rawOptions is Map) {
      for (final entry in rawOptions.entries) {
        final key = entry.key.toString();
        final val = entry.value;
        final double total;
        if (val is Map && val.containsKey('total')) {
          total = _doubleFromJson(val['total']);
        } else {
          total = _doubleFromJson(val);
        }
        if (total > 0) options[key] = total;
      }
    }

    double? recommendedTotal;
    final rawTotal = json['recommended_total'];
    if (rawTotal != null) {
      final parsed = _doubleFromJson(rawTotal);
      if (parsed > 0) recommendedTotal = parsed;
    }
    recommendedTotal ??=
        (recommendedLevel != null ? options[recommendedLevel] : null);

    final rawWarnings = json['warnings'];
    final warnings = rawWarnings is List
        ? rawWarnings.whereType<String>().toList()
        : <String>[];

    // parse vehicle info: nested 'vehicle' map or flat 'vehicle_*' keys
    // year may arrive as a string from backend
    String? vehicleMake;
    String? vehicleModel;
    int? vehicleYear;
    final rawVehicle = json['vehicle'];
    if (rawVehicle is Map) {
      vehicleMake = rawVehicle['make'] as String?;
      vehicleModel = rawVehicle['model'] as String?;
      final rawYear = rawVehicle['year'];
      vehicleYear = rawYear is num
          ? rawYear.toInt()
          : (rawYear is String ? int.tryParse(rawYear) : null);
    }
    vehicleMake ??= json['vehicle_make'] as String?;
    vehicleModel ??= json['vehicle_model'] as String?;
    if (vehicleYear == null) {
      final rawYear = json['vehicle_year'];
      vehicleYear = rawYear is num
          ? rawYear.toInt()
          : (rawYear is String ? int.tryParse(rawYear) : null);
    }

    return CostEstimation(
      recommendedTotal: recommendedTotal,
      recommendedLevel: recommendedLevel,
      options: Map.unmodifiable(options),
      dataSource: json['data_source'] as String?,
      warnings: List.unmodifiable(warnings),
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      vehicleYear: vehicleYear,
    );
  }
}
