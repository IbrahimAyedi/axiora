import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/ocr_result.dart';
// service principal mte3 OCR
// yesta3mel Google ML Kit Text Recognition bech ya9ra text men image
// ba3ed yparse raw text l data structured: carte grise, assurance, permis
class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Recognize text from image file
  Future<OcrTextResult> recognizeFromFile(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final lines = recognizedText.blocks
          .expand((block) => block.lines)
          .map((line) => line.text)
          .toList();

      final rawText = recognizedText.text;

      return OcrTextResult(
        rawText: rawText,
        lines: lines,
        processedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Error processing image: $e');
    }
  }

  /// Extract structured vehicle data from OCR text (Tunisian carte grise)
  VehicleDocumentData parseVehicleDocument(OcrTextResult ocrResult) {
    final rawText = ocrResult.rawText;
    final lines = ocrResult.lines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (kDebugMode) {
      debugPrint('RAW CARTE GRISE OCR TEXT START');
      debugPrint(rawText);
      debugPrint('RAW CARTE GRISE OCR TEXT END');
    }

    String? ownerName;
    String? ownerCin;
    String? plateNumber;
    String? vin;
    String? registrationNumber;
    String? brand;
    String? model;
    String? vehicleType;
    String? registrationDate;

    // Extract VIN first (17 characters alphanumeric, excluding I, O, Q)
    vin = _carteGriseExtractVin(rawText, lines);

    // Extract brand (Constructeur / الصانع) - pass VIN to exclude fragments
    brand = _carteGriseExtractBrand(lines, vin);

    // Extract model (Type commercial / النوع التجاري) - pass VIN to exclude fragments
    model = _carteGriseExtractModel(lines, vin);

    // Extract plate number (Tunisian format) - pass VIN to exclude fragments
    plateNumber = _carteGriseExtractPlateNumber(rawText, lines, vin);

    // Extract owner name (Nom et Prénom / الاسم واللقب)
    ownerName = _carteGriseExtractOwnerName(lines);

    // Extract owner CIN
    ownerCin = _carteGriseExtractOwnerCin(lines);

    // Extract vehicle type (Genre)
    vehicleType = _carteGriseExtractVehicleType(lines);

    // Extract first registration date (Date première mise en circulation / تاريخ أول إذن بالجولان)
    registrationDate = _carteGriseExtractRegistrationDate(lines);

    // Calculate confidence based on extracted fields (VIN and brand are most important)
    int extractedFields = 0;
    if (vin != null) extractedFields++;
    if (brand != null) extractedFields++;
    if (model != null) extractedFields++;
    if (plateNumber != null) extractedFields++;
    double confidence = extractedFields / 4.0;

    if (kDebugMode) {
      debugPrint('Extracted carte grise fields:');
      debugPrint('  vin: $vin');
      debugPrint('  brand: $brand');
      debugPrint('  model: $model');
      debugPrint('  plateNumber: $plateNumber');
      debugPrint('  ownerName: $ownerName');
      debugPrint('  ownerCin: $ownerCin');
      debugPrint('  vehicleType: $vehicleType');
      debugPrint('  registrationDate: $registrationDate');
      debugPrint('  confidence: $confidence');
    }

    return VehicleDocumentData(
      ownerName: ownerName,
      plateNumber: plateNumber,
      vin: vin,
      registrationNumber: registrationNumber,
      brand: brand,
      model: model,
      registrationDate: registrationDate,
      rawText: ocrResult.rawText,
      confidence: confidence,
    );
  }

  /// Extract structured insurance document data from OCR text (Tunisian attestation d'assurance)
  InsuranceDocumentData parseInsuranceDocument(OcrTextResult ocrResult) {
    final rawText = ocrResult.rawText;
    final lines = ocrResult.lines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (kDebugMode) {
      debugPrint('RAW ASSURANCE OCR TEXT START');
      debugPrint(rawText);
      debugPrint('RAW ASSURANCE OCR TEXT END');
    }

    String? insuranceNumber;
    String? companyName;
    String? policyHolderName;
    String? policyType;
    String? contractNumber;
    String? validFrom;
    String? validTo;
    String? vehiclePlate;
    String? vin;
    String? vehicleBrand;
    String? vehicleModel;

    // Extract insurance number (near Attestation d'Assurance / شهادة تأمين)
    insuranceNumber = _insuranceExtractInsuranceNumber(rawText, lines);

    // Extract company name (Entreprise d'Assurance / مؤسسة التأمين)
    companyName = _insuranceExtractCompanyName(lines);

    // Extract policy holder name (Assuré / Participant / المؤمن له)
    policyHolderName = _insuranceExtractPolicyHolderName(lines);

    // Extract policy type / usage (Usage / الاستعمال)
    policyType = _insuranceExtractPolicyType(lines);

    // Extract contract number (Contrat N° / عدد العقد)
    contractNumber = _insuranceExtractContractNumber(lines);

    // Extract validity dates (Validité Du/Au / من/إلى)
    final validityDates = _insuranceExtractValidityDates(lines);
    validFrom = validityDates['from'];
    validTo = validityDates['to'];

    // Extract vehicle information (optional)
    vehicleBrand = _insuranceExtractVehicleBrand(lines);
    vehicleModel = _insuranceExtractVehicleModel(lines);
    vin = _insuranceExtractVehicleVin(lines);
    vehiclePlate = _insuranceExtractVehiclePlate(lines);

    // Calculate confidence based on extracted fields
    int extractedFields = 0;
    if (insuranceNumber != null) extractedFields++;
    if (companyName != null) extractedFields++;
    if (policyHolderName != null) extractedFields++;
    if (policyType != null) extractedFields++;
    double confidence = extractedFields / 4.0;

    if (kDebugMode) {
      debugPrint('Extracted insurance fields:');
      debugPrint('  insuranceNumber: $insuranceNumber');
      debugPrint('  companyName: $companyName');
      debugPrint('  policyHolderName: $policyHolderName');
      debugPrint('  policyType: $policyType');
      debugPrint('  contractNumber: $contractNumber');
      debugPrint('  validFrom: $validFrom');
      debugPrint('  validTo: $validTo');
      debugPrint('  vehicleBrand: $vehicleBrand');
      debugPrint('  vehicleModel: $vehicleModel');
      debugPrint('  vin: $vin');
      debugPrint('  vehiclePlate: $vehiclePlate');
      debugPrint('  confidence: $confidence');
    }

    return InsuranceDocumentData(
      insuranceNumber: insuranceNumber,
      companyName: companyName,
      policyHolderName: policyHolderName,
      policyType: policyType,
      contractNumber: contractNumber,
      validFrom: validFrom,
      validTo: validTo,
      vehiclePlate: vehiclePlate,
      vin: vin,
      vehicleBrand: vehicleBrand,
      vehicleModel: vehicleModel,
      rawText: ocrResult.rawText,
      confidence: confidence,
    );
  }

  /// Extract structured driver license data from OCR text
  DriverLicenseData parseDriverLicense(OcrTextResult ocrResult) {
    final rawText = ocrResult.rawText;
    final searchableText = _normalizeForSearch(rawText);
    final lines = ocrResult.lines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final numberedFields = _extractNumberedFields(rawText, lines);
    final layout = _detectTunisianLicenseLayout(numberedFields, rawText);
    final nationalIdCandidates = _nationalIdCandidatesFromText(rawText);
    final rawLicenseCandidates = _rawTunisianLicenseCandidates(
      rawText,
      excludedCompactValues: nationalIdCandidates,
    );
    final licenseCandidates = rawLicenseCandidates
        .map((candidate) => candidate.normalized)
        .toSet()
        .toList();

    if (kDebugMode) {
      debugPrint('RAW OCR TEXT START');
      debugPrint(rawText);
      debugPrint('RAW OCR TEXT END');
      debugPrint('detected layout: ${layout.name}');
      debugPrint('extracted marker fields map: $numberedFields');
      debugPrint('field 5 raw value: ${numberedFields['5'] ?? '<missing>'}');
      debugPrint(
        'raw license candidates: '
        '${rawLicenseCandidates.map((candidate) => candidate.raw).toList()}',
      );
      debugPrint('normalized license candidates: $licenseCandidates');
      debugPrint('CIN candidates: $nationalIdCandidates');
    }

    String? fullName;
    String? firstName;
    String? lastName;
    String? dateOfBirth;
    String? birthPlace;
    String? licenseNumber;
    String? nationalId;
    String? issueDate;
    String? issuingCountry;
    String? issuingAuthority;
    String? expiryDate;
    String? address;
    String? category;

    switch (layout) {
      case _TunisianLicenseLayout.newFormat:
        lastName = _nameFromNumberedField(numberedFields['1']);
        firstName = _nameFromNumberedField(numberedFields['2']);
        final nameFallback = _newLayoutNameFallback(
          lines: lines,
          firstName: firstName,
          lastName: lastName,
          birthPlace: _placeFromDateField(numberedFields['3']),
        );
        firstName ??= nameFallback.firstName;
        lastName ??= nameFallback.lastName;
        fullName = _combineName(firstName, lastName);
        dateOfBirth = _dateFromText(numberedFields['3']);
        birthPlace = _placeFromDateField(numberedFields['3']);
        issueDate = _dateFromText(numberedFields['4a']);
        expiryDate = _dateFromText(numberedFields['4b']);
        issuingAuthority = _plainTextFromNumberedField(numberedFields['4c']);
        nationalId =
            _nationalIdFromNumberedField(numberedFields['4d']) ??
            _firstOrNull(nationalIdCandidates) ??
            _nationalIdNearLabel(lines);
        licenseNumber =
            _firstOrNull(licenseCandidates) ??
            _licenseFromNumberedField(numberedFields['5']) ??
            _licenseNearLabel(lines);
        category = _categoryFromNumberedField(numberedFields['9']);
        break;
      case _TunisianLicenseLayout.oldFormat:
        licenseNumber =
            _licenseFromNumberedField(numberedFields['1']) ??
            _licenseNearLabel(lines);
        issueDate = _dateFromText(numberedFields['2']);
        lastName = _nameFromNumberedField(numberedFields['3']);
        firstName = _nameFromNumberedField(numberedFields['4']);
        fullName = _combineName(firstName, lastName);
        birthPlace = _plainTextFromNumberedField(numberedFields['5']);
        nationalId =
            _nationalIdFromNumberedField(numberedFields['6']) ??
            _nationalIdNearLabel(lines);
        address = _plainTextFromNumberedField(numberedFields['7']);
        category = _categoryFromNumberedField(numberedFields['8']);
        break;
    }

    lastName ??= _nameNearLabel(lines, const [
      'NOM',
      'SURNAME',
      'LAST NAME',
      'FAMILY NAME',
      '\u0627\u0644\u0644\u0642\u0628',
    ]);
    firstName ??= _nameNearLabel(lines, const [
      'PRENOM',
      'PRENOMS',
      'FIRST NAME',
      'GIVEN NAME',
      '\u0627\u0644\u0627\u0633\u0645',
    ]);

    fullName ??=
        _combineName(firstName, lastName) ??
        _nameNearLabel(lines, const [
          'NOM ET PRENOM',
          'NOM PRENOM',
          'FULL NAME',
          'NAME',
          '\u0627\u0644\u0627\u0633\u0645 \u0627\u0644\u0643\u0627\u0645\u0644',
        ]);

    dateOfBirth ??= _dateNearLabel(lines, const [
      'DATE DE NAISSANCE',
      'NAISSANCE',
      'NE LE',
      'NEE LE',
      'BIRTH',
      'DATE OF BIRTH',
      'DOB',
      '\u062a\u0627\u0631\u064a\u062e \u0627\u0644\u0627\u0632\u062f\u064a\u0627\u062f',
      '\u062a\u0627\u0631\u064a\u062e \u0627\u0644\u0645\u064a\u0644\u0627\u062f',
    ]);
    expiryDate ??= _dateNearLabel(lines, const [
      'DATE D EXPIRATION',
      'EXPIRATION',
      'EXPIRY',
      'EXPIRE',
      'VALIDITE',
      'VALID UNTIL',
      '4B',
      '\u0627\u0644\u0635\u0644\u0627\u062d\u064a\u0629',
    ]);
    if (searchableText.contains('FRANCE') ||
        RegExp(r'\bFR\b').hasMatch(searchableText)) {
      issuingCountry = 'FR';
    } else if (searchableText.contains('MAROC') ||
        searchableText.contains('MOROCCO')) {
      issuingCountry = 'MA';
    } else if (searchableText.contains('ALGERIE') ||
        searchableText.contains('ALGERIA')) {
      issuingCountry = 'DZ';
    } else if (searchableText.contains('TUNISIE') ||
        searchableText.contains('TUNISIA')) {
      issuingCountry = 'TN';
    }

    // Calculate confidence
    int extractedFields = 0;
    if (fullName != null) extractedFields++;
    if (licenseNumber != null) extractedFields++;
    if (nationalId != null) extractedFields++;
    if (dateOfBirth != null) extractedFields++;
    double confidence = extractedFields / 4.0;

    final driverData = DriverLicenseData(
      fullName: fullName,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      birthPlace: birthPlace,
      licenseNumber: licenseNumber,
      nationalId: nationalId,
      issueDate: issueDate,
      issuingCountry: issuingCountry,
      issuingAuthority: issuingAuthority,
      expiryDate: expiryDate,
      address: address,
      category: category,
      rawText: ocrResult.rawText,
      confidence: confidence,
    );

    if (kDebugMode) {
      debugPrint('selected license candidate: $licenseNumber');
      debugPrint(
        'final DriverLicenseData values: '
        'fullName=${driverData.fullName}, '
        'firstName=${driverData.firstName}, '
        'lastName=${driverData.lastName}, '
        'licenseNumber=${driverData.licenseNumber}, '
        'nationalId=${driverData.nationalId}, '
        'dateOfBirth=${driverData.dateOfBirth}, '
        'birthPlace=${driverData.birthPlace}, '
        'issueDate=${driverData.issueDate}, '
        'expiryDate=${driverData.expiryDate}, '
        'issuingAuthority=${driverData.issuingAuthority}, '
        'address=${driverData.address}, '
        'category=${driverData.category}, '
        'confidence=${driverData.confidence}',
      );
    }

    return driverData;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}

// ============================================================================
// Carte Grise (Vehicle Registration) Parsing Helper Functions
// ============================================================================

/// Extract VIN from carte grise OCR text
/// VIN is typically 17 characters, alphanumeric, excluding I, O, Q
String? _carteGriseExtractVin(String rawText, List<String> lines) {
  if (kDebugMode) {
    debugPrint('VIN extraction starting...');
  }

  // VIN pattern: 17 characters, excluding I, O, Q
  final vinPattern = RegExp(r'\b[A-HJ-NPR-Z0-9]{17}\b');

  // First try: exact 17-character match without spaces
  final vinMatch = vinPattern.firstMatch(rawText.toUpperCase());
  if (vinMatch != null) {
    if (kDebugMode) {
      debugPrint('VIN found (exact match): ${vinMatch.group(0)}');
    }
    return vinMatch.group(0);
  }

  // Second try: VIN with spaces, dashes, or slashes
  // Pattern: 9-10 chars + separator + 7-8 chars = 17 total
  final vinWithSeparatorPattern = RegExp(
    r'\b([A-HJ-NPR-Z0-9]{9,10})[\s\-/]+([A-HJ-NPR-Z0-9]{7,8})\b',
    caseSensitive: false,
  );

  for (final match in vinWithSeparatorPattern.allMatches(
    rawText.toUpperCase(),
  )) {
    final part1 = match.group(1) ?? '';
    final part2 = match.group(2) ?? '';
    final combined = part1 + part2;

    // Must be exactly 17 characters when combined
    if (combined.length == 17) {
      if (kDebugMode) {
        debugPrint('VIN found (with separator): $part1 + $part2 = $combined');
      }
      return combined;
    }
  }

  // Third try: Look near VIN labels
  final vinLabels = [
    'N SERIE',
    'N° SERIE',
    'NUMERO SERIE',
    'N SERIE DU TYPE',
    'N° SERIE DU TYPE',
    'VIN',
    'CHASSIS',
    'رقم الهيكل',
  ];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final normalizedLine = _normalizeForSearch(line);

    for (final label in vinLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label)) {
        // Check same line
        final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
        if (sameLineValue != null) {
          // Try exact match
          final vinMatch = vinPattern.firstMatch(sameLineValue.toUpperCase());
          if (vinMatch != null) {
            if (kDebugMode) {
              debugPrint(
                'VIN found (after label, same line): ${vinMatch.group(0)}',
              );
            }
            return vinMatch.group(0);
          }

          // Try with separator
          final separatorMatch = vinWithSeparatorPattern.firstMatch(
            sameLineValue.toUpperCase(),
          );
          if (separatorMatch != null) {
            final part1 = separatorMatch.group(1) ?? '';
            final part2 = separatorMatch.group(2) ?? '';
            final combined = part1 + part2;
            if (combined.length == 17) {
              if (kDebugMode) {
                debugPrint(
                  'VIN found (after label, with separator): $combined',
                );
              }
              return combined;
            }
          }
        }

        // Check next lines
        for (var j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j];

          // Try exact match
          final vinMatch = vinPattern.firstMatch(nextLine.toUpperCase());
          if (vinMatch != null) {
            if (kDebugMode) {
              debugPrint(
                'VIN found (next line after label): ${vinMatch.group(0)}',
              );
            }
            return vinMatch.group(0);
          }

          // Try with separator
          final separatorMatch = vinWithSeparatorPattern.firstMatch(
            nextLine.toUpperCase(),
          );
          if (separatorMatch != null) {
            final part1 = separatorMatch.group(1) ?? '';
            final part2 = separatorMatch.group(2) ?? '';
            final combined = part1 + part2;
            if (combined.length == 17) {
              if (kDebugMode) {
                debugPrint('VIN found (next line, with separator): $combined');
              }
              return combined;
            }
          }
        }
      }
    }
  }

  if (kDebugMode) {
    debugPrint('No VIN found');
  }
  return null;
}

/// Extract plate number from carte grise OCR text
/// Tunisian plates can have various formats
String? _carteGriseExtractPlateNumber(
  String rawText,
  List<String> lines,
  String? vin,
) {
  final plateCandidates = <String>[];

  if (kDebugMode) {
    debugPrint('Plate number extraction starting...');
    debugPrint('VIN to exclude from plate: $vin');
  }

  // Try Tunisian plate patterns in single line
  // Common formats: 123 TU 1234, 123 TUNIS 1234, 123 تونس 1234
  final singleLinePlatePatterns = [
    // Standard format with clear marker
    RegExp(
      r'\b(\d{1,4})\s*(TU|TUNIS|TUNISIE|TN)\s*(\d{3,4})\b',
      caseSensitive: false,
    ),
    // With Arabic تونس
    RegExp(r'\b(\d{1,4})\s*تونس\s*(\d{3,4})\b'),
    // With noisy OCR markers (wuii, tuni, tn, etc.)
    RegExp(
      r'\b(\d{1,4})\s*(wuii|tuni|tunis|tunisie|tn|tu)\s*(\d{3,4})\b',
      caseSensitive: false,
    ),
  ];

  for (final pattern in singleLinePlatePatterns) {
    for (final match in pattern.allMatches(rawText)) {
      final firstNum = match.group(1) ?? '';
      final secondNum = match.groupCount >= 3 ? match.group(3) : match.group(2);

      if (firstNum.isNotEmpty && secondNum != null && secondNum.isNotEmpty) {
        if (_isValidTunisianPlate(firstNum, secondNum, vin)) {
          final normalized = _normalizeTunisianPlate(firstNum, secondNum);
          plateCandidates.add(normalized);
          if (kDebugMode) {
            debugPrint(
              'Plate candidate from single line pattern: $normalized (raw: ${match.group(0)})',
            );
          }
        } else if (kDebugMode) {
          debugPrint(
            'Rejected plate candidate: $firstNum TU $secondNum (validation failed)',
          );
        }
      }
    }
  }

  // Try multi-line Tunisian plate detection
  // Line 1: first number (e.g., "148")
  // Line 2: marker + second number (e.g., "wuii 6968" or "تونس 6968")
  for (var i = 0; i < lines.length - 1; i++) {
    final line1 = lines[i].trim();
    final line2 = lines[i + 1].trim();

    // Check if line1 is a short number (1-4 digits)
    final firstNumMatch = RegExp(r'^(\d{1,4})$').firstMatch(line1);
    if (firstNumMatch == null) continue;

    final firstNum = firstNumMatch.group(1)!;

    // Check if line2 contains marker + second number
    final line2Patterns = [
      // With clear marker
      RegExp(r'^(TU|TUNIS|TUNISIE|TN|تونس)\s*(\d{3,4})$', caseSensitive: false),
      // With noisy marker
      RegExp(
        r'^(wuii|tuni|tunis|tunisie|tn|tu)\s*(\d{3,4})$',
        caseSensitive: false,
      ),
      // Marker and number together (e.g., "wuii6968")
      RegExp(
        r'^(wuii|tuni|tunis|tunisie|tn|tu|تونس)(\d{3,4})$',
        caseSensitive: false,
      ),
      // Just the second number if first line was a plate number
      RegExp(r'^(\d{3,4})$'),
    ];

    for (final pattern in line2Patterns) {
      final match = pattern.firstMatch(line2);
      if (match != null) {
        final secondNum = match.groupCount >= 2 && match.group(2) != null
            ? match.group(2)!
            : match.group(1)!;

        // If secondNum is not a number, skip
        if (!RegExp(r'^\d{3,4}$').hasMatch(secondNum)) continue;

        if (_isValidTunisianPlate(firstNum, secondNum, vin)) {
          final normalized = _normalizeTunisianPlate(firstNum, secondNum);
          plateCandidates.add(normalized);
          if (kDebugMode) {
            debugPrint(
              'Plate candidate from multi-line: $normalized (line1: $line1, line2: $line2)',
            );
          }
        } else if (kDebugMode) {
          debugPrint(
            'Rejected plate candidate: $firstNum TU $secondNum (validation failed)',
          );
        }
        break;
      }
    }
  }

  // Try to find near labels
  final plateLabels = [
    'IMMATRICULATION',
    'N IMMATRICULATION',
    'N° IMMATRICULATION',
    'NUMERO IMMATRICULATION',
    'PLAQUE',
    'رقم التسجيل',
  ];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final normalizedLine = _normalizeForSearch(line);

    for (final label in plateLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label)) {
        // Check same line
        final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
        if (sameLineValue != null) {
          for (final pattern in singleLinePlatePatterns) {
            final match = pattern.firstMatch(sameLineValue);
            if (match != null) {
              final firstNum = match.group(1) ?? '';
              final secondNum = match.groupCount >= 3
                  ? match.group(3)
                  : match.group(2);

              if (firstNum.isNotEmpty &&
                  secondNum != null &&
                  secondNum.isNotEmpty) {
                if (_isValidTunisianPlate(firstNum, secondNum, vin)) {
                  final normalized = _normalizeTunisianPlate(
                    firstNum,
                    secondNum,
                  );
                  plateCandidates.add(normalized);
                  if (kDebugMode) {
                    debugPrint(
                      'Plate candidate from same line after "$label": $normalized',
                    );
                  }
                }
              }
            }
          }
        }

        // Check next lines
        for (var j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim();

          for (final pattern in singleLinePlatePatterns) {
            final match = pattern.firstMatch(nextLine);
            if (match != null) {
              final firstNum = match.group(1) ?? '';
              final secondNum = match.groupCount >= 3
                  ? match.group(3)
                  : match.group(2);

              if (firstNum.isNotEmpty &&
                  secondNum != null &&
                  secondNum.isNotEmpty) {
                if (_isValidTunisianPlate(firstNum, secondNum, vin)) {
                  final normalized = _normalizeTunisianPlate(
                    firstNum,
                    secondNum,
                  );
                  plateCandidates.add(normalized);
                  if (kDebugMode) {
                    debugPrint(
                      'Plate candidate from next line after "$label": $normalized',
                    );
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  if (kDebugMode) {
    debugPrint('All plate candidates: $plateCandidates');
  }

  // Return first candidate if found
  if (plateCandidates.isNotEmpty) {
    if (kDebugMode) {
      debugPrint('Selected plate: ${plateCandidates.first}');
    }
    return plateCandidates.first;
  }

  if (kDebugMode) {
    debugPrint('No confident plate number found (leaving empty)');
  }
  return null;
}

/// Validate if the extracted numbers form a valid Tunisian plate
bool _isValidTunisianPlate(String firstNum, String secondNum, String? vin) {
  // First number: 1-4 digits
  if (firstNum.isEmpty || firstNum.length > 4) {
    if (kDebugMode) {
      debugPrint('Rejected plate: first number length invalid ($firstNum)');
    }
    return false;
  }

  // Second number: 3-4 digits
  if (secondNum.length < 3 || secondNum.length > 4) {
    if (kDebugMode) {
      debugPrint('Rejected plate: second number length invalid ($secondNum)');
    }
    return false;
  }

  // Exclude if it's a VIN fragment
  final combined = firstNum + secondNum;
  if (vin != null) {
    final vinUpper = vin.toUpperCase();
    if (vinUpper.contains(combined) || combined.contains(vinUpper)) {
      if (kDebugMode) {
        debugPrint('Rejected plate: VIN fragment ($firstNum TU $secondNum)');
      }
      return false;
    }
  }

  // Exclude if it looks like a CIN (8 digits total)
  if (combined.length == 8) {
    if (kDebugMode) {
      debugPrint('Rejected plate: looks like CIN ($firstNum TU $secondNum)');
    }
    return false;
  }

  // Exclude if first number is too large (likely year or other data)
  final firstNumInt = int.tryParse(firstNum);
  if (firstNumInt != null && firstNumInt > 9999) {
    if (kDebugMode) {
      debugPrint('Rejected plate: first number too large ($firstNum)');
    }
    return false;
  }

  // Exclude common date/year patterns
  if (firstNumInt != null && (firstNumInt >= 1900 && firstNumInt <= 2099)) {
    if (kDebugMode) {
      debugPrint('Rejected plate: looks like year ($firstNum)');
    }
    return false;
  }

  return true;
}

/// Normalize Tunisian plate to standard format: shorter number + TU + longer number
/// Example: "6968 TU 148" -> "148 TU 6968"
String _normalizeTunisianPlate(String firstNum, String secondNum) {
  // Prefer shorter/smaller number first, longer/larger number second
  // This matches Tunisian plate format: 1-4 digits + TU + 3-4 digits

  // If lengths are different, put shorter one first
  if (firstNum.length < secondNum.length) {
    return '$firstNum TU $secondNum';
  } else if (secondNum.length < firstNum.length) {
    return '$secondNum TU $firstNum';
  }

  // If same length, prefer smaller numeric value first
  final firstInt = int.tryParse(firstNum);
  final secondInt = int.tryParse(secondNum);

  if (firstInt != null && secondInt != null) {
    if (firstInt < secondInt) {
      return '$firstNum TU $secondNum';
    } else if (secondInt < firstInt) {
      return '$secondNum TU $firstNum';
    }
  }

  // If ambiguous, keep original order
  return '$firstNum TU $secondNum';
}

/// Extract brand/manufacturer from carte grise OCR text
String? _carteGriseExtractBrand(List<String> lines, String? vin) {
  final brandLabels = [
    'CONSTRUCTEUR',
    'MARQUE',
    'FABRICANT',
    'MANUFACTURER',
    'MAKE',
    'الصانع',
  ];

  // Common vehicle brands for validation
  final knownBrands = {
    'MERCEDES',
    'MERCEDES-BENZ',
    'MERCEDES BENZ',
    'PEUGEOT',
    'RENAULT',
    'TOYOTA',
    'CITROEN',
    'CITROËN',
    'VOLKSWAGEN',
    'BMW',
    'AUDI',
    'FIAT',
    'HYUNDAI',
    'KIA',
    'NISSAN',
    'FORD',
    'OPEL',
    'SEAT',
    'SKODA',
    'MAZDA',
    'HONDA',
    'MITSUBISHI',
    'SUZUKI',
    'DACIA',
    'CHEVROLET',
    'VOLVO',
    'IVECO',
  };

  final brandCandidates = <String>[];

  if (kDebugMode) {
    debugPrint('Brand extraction - VIN to exclude: $vin');
  }

  // FIRST: Search for known brands anywhere in the OCR text
  for (final line in lines) {
    final cleaned = line.trim().toUpperCase();
    final normalized = _normalizeForSearch(cleaned);

    // Skip if it's a label or noise
    if (_isCarteGriseLabel(normalized)) {
      if (kDebugMode) {
        debugPrint('Skipping line (label/noise): $cleaned');
      }
      continue;
    }

    // Check if this line is or contains a known brand
    for (final knownBrand in knownBrands) {
      final normalizedBrand = _normalizeForSearch(knownBrand);
      if (normalized == normalizedBrand ||
          normalized.contains(normalizedBrand) ||
          normalizedBrand.contains(normalized)) {
        // Additional validation
        if (_isValidBrandCandidate(cleaned, vin, knownBrands)) {
          brandCandidates.add(cleaned);
          if (kDebugMode) {
            debugPrint('Brand candidate (known brand found): $cleaned');
          }
          break;
        }
      }
    }
  }

  // If we found known brands, prefer them
  if (brandCandidates.isNotEmpty) {
    if (kDebugMode) {
      debugPrint('All brand candidates: $brandCandidates');
      debugPrint('Selected brand (known): ${brandCandidates.first}');
    }
    return brandCandidates.first;
  }

  // SECOND: Try label-neighbor extraction with strict validation
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final normalizedLine = _normalizeForSearch(line);

    for (final label in brandLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label)) {
        // Check same line
        final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
        if (sameLineValue != null &&
            _isValidBrandCandidate(sameLineValue, vin, knownBrands)) {
          brandCandidates.add(sameLineValue.trim().toUpperCase());
          if (kDebugMode) {
            debugPrint(
              'Brand candidate from same line after "$label": ${sameLineValue.trim().toUpperCase()}',
            );
          }
        }

        // Check next lines with strict validation
        for (var j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j].trim();
          final normalizedNext = _normalizeForSearch(nextLine);

          // Skip if it's a label or noise
          if (_isCarteGriseLabel(normalizedNext)) {
            if (kDebugMode) {
              debugPrint('Rejected brand candidate (label/noise): $nextLine');
            }
            continue;
          }

          if (_isValidBrandCandidate(nextLine, vin, knownBrands)) {
            brandCandidates.add(nextLine.toUpperCase());
            if (kDebugMode) {
              debugPrint(
                'Brand candidate from next line after "$label": ${nextLine.toUpperCase()}',
              );
            }
          }
        }
      }
    }
  }

  if (kDebugMode) {
    debugPrint('All brand candidates: $brandCandidates');
  }

  // Return first valid candidate
  if (brandCandidates.isNotEmpty) {
    if (kDebugMode) {
      debugPrint('Selected brand: ${brandCandidates.first}');
    }
    return brandCandidates.first;
  }

  if (kDebugMode) {
    debugPrint('No valid brand found');
  }
  return null;
}

/// Extract model from carte grise OCR text
String? _carteGriseExtractModel(List<String> lines, String? vin) {
  final modelLabels = [
    'TYPE COMMERCIAL',
    'TYPE',
    'MODELE',
    'MODEL',
    'النوع التجاري',
    'النوع',
  ];

  // Known brands to exclude from model
  final knownBrands = {
    'MERCEDES',
    'MERCEDES-BENZ',
    'MERCEDES BENZ',
    'PEUGEOT',
    'RENAULT',
    'TOYOTA',
    'CITROEN',
    'CITROËN',
    'VOLKSWAGEN',
    'BMW',
    'AUDI',
    'FIAT',
    'HYUNDAI',
    'KIA',
    'NISSAN',
    'FORD',
    'OPEL',
    'SEAT',
    'SKODA',
    'MAZDA',
    'HONDA',
    'MITSUBISHI',
    'SUZUKI',
    'DACIA',
    'CHEVROLET',
    'VOLVO',
    'IVECO',
  };

  final modelCandidates = <String>[];

  if (kDebugMode) {
    debugPrint('Model extraction - VIN to exclude: $vin');
  }

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final normalizedLine = _normalizeForSearch(line);

    for (final label in modelLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label)) {
        // Check same line
        final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
        if (sameLineValue != null &&
            _isValidModelCandidate(sameLineValue, vin, knownBrands)) {
          modelCandidates.add(sameLineValue.trim());
          if (kDebugMode) {
            debugPrint(
              'Model candidate from same line after "$label": ${sameLineValue.trim()}',
            );
          }
        }

        // Check next lines with strict validation
        for (var j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j].trim();
          final normalizedNext = _normalizeForSearch(nextLine);

          // Skip if it's a label or noise
          if (_isCarteGriseLabel(normalizedNext)) {
            if (kDebugMode) {
              debugPrint('Rejected model candidate (label/noise): $nextLine');
            }
            continue;
          }

          if (_isValidModelCandidate(nextLine, vin, knownBrands)) {
            modelCandidates.add(nextLine);
            if (kDebugMode) {
              debugPrint(
                'Model candidate from next line after "$label": $nextLine',
              );
            }
          }
        }
      }
    }
  }

  if (kDebugMode) {
    debugPrint('All model candidates: $modelCandidates');
  }

  // Return first valid candidate, or null if none found
  if (modelCandidates.isNotEmpty) {
    if (kDebugMode) {
      debugPrint('Selected model: ${modelCandidates.first}');
    }
    return modelCandidates.first;
  }

  if (kDebugMode) {
    debugPrint('No valid model found (leaving empty)');
  }
  return null;
}

/// Extract owner name from carte grise OCR text
String? _carteGriseExtractOwnerName(List<String> lines) {
  final ownerLabels = [
    'NOM ET PRENOM',
    'NOM PRENOM',
    'PROPRIETAIRE',
    'OWNER',
    'الاسم واللقب',
  ];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final normalizedLine = _normalizeForSearch(line);

    for (final label in ownerLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label)) {
        // Check same line
        final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
        if (sameLineValue != null && _isLikelyName(sameLineValue)) {
          final normalized = _normalizeForSearch(sameLineValue);
          // Reject DPMC and other labels
          if (!_isCarteGriseLabel(normalized)) {
            return sameLineValue.trim();
          }
        }

        // Check next lines
        for (var j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j].trim();
          if (_isLikelyName(nextLine)) {
            final normalized = _normalizeForSearch(nextLine);
            // Reject DPMC and other labels
            if (!_isCarteGriseLabel(normalized)) {
              return nextLine;
            }
          }
        }
      }
    }
  }

  return null;
}

/// Extract owner CIN from carte grise OCR text
String? _carteGriseExtractOwnerCin(List<String> lines) {
  final cinLabels = [
    'CIN',
    'N CIN',
    'N° CIN',
    'NUMERO CIN',
    'CARTE IDENTITE',
    'بطاقة التعريف',
  ];

  // CIN pattern: 8 digits
  final cinPattern = RegExp(r'\b\d{8}\b');

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final normalizedLine = _normalizeForSearch(line);

    for (final label in cinLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label)) {
        // Check same line
        final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
        if (sameLineValue != null) {
          final cinMatch = cinPattern.firstMatch(sameLineValue);
          if (cinMatch != null) return cinMatch.group(0);
        }

        // Check next lines
        for (var j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j];
          final cinMatch = cinPattern.firstMatch(nextLine);
          if (cinMatch != null) return cinMatch.group(0);
        }
      }
    }
  }

  return null;
}

/// Extract vehicle type from carte grise OCR text
String? _carteGriseExtractVehicleType(List<String> lines) {
  final typeLabels = ['GENRE', 'TYPE VEHICULE', 'VEHICLE TYPE', 'CATEGORY'];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final normalizedLine = _normalizeForSearch(line);

    for (final label in typeLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label)) {
        // Check same line
        final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
        if (sameLineValue != null && sameLineValue.trim().length >= 2) {
          return sameLineValue.trim();
        }

        // Check next lines
        for (var j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j].trim();
          if (nextLine.length >= 2 && nextLine.length <= 30) {
            return nextLine;
          }
        }
      }
    }
  }

  return null;
}

/// Extract first registration date from carte grise OCR text
String? _carteGriseExtractRegistrationDate(List<String> lines) {
  final dateLabels = [
    'DATE PREMIERE MISE EN CIRCULATION',
    'PREMIERE MISE EN CIRCULATION',
    'MISE EN CIRCULATION',
    'DATE IMMATRICULATION',
    'FIRST REGISTRATION',
    'تاريخ أول إذن بالجولان',
  ];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final normalizedLine = _normalizeForSearch(line);

    for (final label in dateLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label)) {
        // Check same line
        final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
        if (sameLineValue != null) {
          final dates = _extractDates(sameLineValue);
          if (dates.isNotEmpty) return dates.first;
        }

        // Check next lines
        for (var j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j];
          final dates = _extractDates(nextLine);
          if (dates.isNotEmpty) return dates.first;
        }
      }
    }
  }

  return null;
}

/// Check if a value is a carte grise label or noise
bool _isCarteGriseLabel(String normalizedValue) {
  final labels = {
    'GENRE',
    'ACTIVITE',
    'ACTIVITÉ',
    'ACTIVITE AL',
    'ACTIVITÉ AL',
    'ADRESSE',
    'DPMC',
    'NOM ET PRENOM',
    'NOM ET PRÉNOM',
    'NOM PRENOM',
    'TYPE',
    'TYPE COMMERCIAL',
    'TYPE CONSTRUCTEUR',
    'CONSTRUCTEUR',
    'HA CONSTRUCTEUR',
    'COMMERCIAL',
    'CERTIFICAT',
    'IMMATRICULATION',
    'CIN',
    'CN',
    'MF',
    'MARQUE',
    'FABRICANT',
    'PROPRIETAIRE',
    'PROPRIÉTAIRE',
    'OWNER',
    'DATE',
    'NUMERO',
    'NUMBER',
    'SERIE',
    'CHASSIS',
    'VIN',
    'MODELE',
    'MODÈLE',
    'MODEL',
  };

  // Check exact match
  if (labels.contains(normalizedValue)) {
    return true;
  }

  // Check if it contains problematic keywords
  final problematicKeywords = [
    'ACTIVITE',
    'ACTIVITÉ',
    'GENRE',
    'ADRESSE',
    'DPMC',
    'CONSTRUCTEUR',
    'COMMERCIAL',
  ];

  for (final keyword in problematicKeywords) {
    if (normalizedValue.contains(keyword)) {
      return true;
    }
  }

  // Reject CIN-like values (8 digits)
  if (RegExp(r'^\d{8}$').hasMatch(normalizedValue)) {
    return true;
  }

  // Reject date-like values
  if (RegExp(
    r'\d{2,4}[/\-\.]\d{1,2}[/\-\.]\d{1,4}',
  ).hasMatch(normalizedValue)) {
    return true;
  }

  return false;
}

/// Check if a value is a valid brand candidate (excludes labels and VIN fragments)
bool _isValidBrandCandidate(
  String value,
  String? vin,
  Set<String> knownBrands,
) {
  final cleaned = value.trim();
  final normalized = _normalizeForSearch(cleaned);

  // Length check
  if (cleaned.length < 2 || cleaned.length > 30) return false;

  // Must start with a letter
  if (!RegExp(r'^[A-Za-z]').hasMatch(cleaned)) return false;

  // Exclude if it's a VIN or VIN fragment (10+ chars matching VIN)
  if (vin != null && cleaned.length >= 10) {
    final cleanedUpper = cleaned.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    final vinUpper = vin.toUpperCase();
    if (vinUpper.contains(cleanedUpper) || cleanedUpper.contains(vinUpper)) {
      if (kDebugMode) {
        debugPrint('Rejected brand candidate (VIN fragment): $cleaned');
      }
      return false;
    }
  }

  // Exclude carte grise labels
  if (_isCarteGriseLabel(normalized)) {
    if (kDebugMode) {
      debugPrint('Rejected brand candidate (label): $cleaned');
    }
    return false;
  }

  // Exclude if it's a document keyword
  if (_isDocumentKeyword(normalized)) {
    if (kDebugMode) {
      debugPrint('Rejected brand candidate (document keyword): $cleaned');
    }
    return false;
  }

  // Avoid long numbers
  if (RegExp(r'[0-9]{5,}').hasMatch(cleaned)) {
    if (kDebugMode) {
      debugPrint('Rejected brand candidate (long numbers): $cleaned');
    }
    return false;
  }

  return true;
}

/// Check if a value is a valid model candidate (excludes labels, VIN fragments, and brands)
bool _isValidModelCandidate(
  String value,
  String? vin,
  Set<String> knownBrands,
) {
  final cleaned = value.trim();
  final normalized = _normalizeForSearch(cleaned);

  // Length check
  if (cleaned.isEmpty || cleaned.length > 50) return false;

  // Must contain alphanumeric
  if (!RegExp(r'[A-Za-z0-9]').hasMatch(cleaned)) return false;

  // Exclude if it's a VIN or VIN fragment (10+ chars matching VIN)
  if (vin != null && cleaned.length >= 10) {
    final cleanedUpper = cleaned.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    final vinUpper = vin.toUpperCase();
    if (vinUpper.contains(cleanedUpper) || cleanedUpper.contains(vinUpper)) {
      if (kDebugMode) {
        debugPrint('Rejected model candidate (VIN fragment): $cleaned');
      }
      return false;
    }
  }

  // Exclude if it's exactly the VIN
  if (vin != null && cleaned.toUpperCase() == vin.toUpperCase()) {
    if (kDebugMode) {
      debugPrint('Rejected model candidate (exact VIN): $cleaned');
    }
    return false;
  }

  // Exclude if it's a known brand
  for (final knownBrand in knownBrands) {
    final normalizedBrand = _normalizeForSearch(knownBrand);
    if (normalized == normalizedBrand ||
        normalized.contains(normalizedBrand) ||
        normalizedBrand.contains(normalized)) {
      if (kDebugMode) {
        debugPrint('Rejected model candidate (known brand): $cleaned');
      }
      return false;
    }
  }

  // Exclude carte grise labels
  if (_isCarteGriseLabel(normalized)) {
    if (kDebugMode) {
      debugPrint('Rejected model candidate (label): $cleaned');
    }
    return false;
  }

  // Exclude if it's a document keyword
  if (_isDocumentKeyword(normalized)) {
    if (kDebugMode) {
      debugPrint('Rejected model candidate (document keyword): $cleaned');
    }
    return false;
  }

  return true;
}

// ============================================================================
// Insurance Document Parsing Helper Functions
// ============================================================================

/// Extract insurance number from insurance document OCR text
String? _insuranceExtractInsuranceNumber(String rawText, List<String> lines) {
  if (kDebugMode) {
    debugPrint('Insurance number extraction starting...');
  }

  final insuranceCandidates = <String>[];

  // Pattern 1: letters + long digits (e.g., AUT000002950279)
  final insurancePattern = RegExp(r'\b[A-Z]{2,5}\d{10,15}\b');

  // Pattern 2: spaced/dashed numeric fragments (e.g., "02- 2 950 279")
  // Must be long enough to not confuse with dates or short numbers
  final spacedNumericPattern = RegExp(
    r'\b(\d{2,3}[\s\-]+\d[\s\-]+\d{3}[\s\-]+\d{3})\b',
  );

  // Try to find letter+digit pattern in raw text
  for (final match in insurancePattern.allMatches(rawText.toUpperCase())) {
    final candidate = match.group(0);
    if (candidate != null && !_isInsuranceLabel(candidate)) {
      insuranceCandidates.add(candidate);
      if (kDebugMode) {
        debugPrint('Insurance number candidate (letter+digit): $candidate');
      }
    }
  }

  // Try to find spaced/dashed numeric fragments
  for (final match in spacedNumericPattern.allMatches(rawText)) {
    final candidate = match.group(0);
    if (candidate != null) {
      // Normalize: remove spaces and dashes
      final normalized = candidate.replaceAll(RegExp(r'[\s\-]+'), '');

      // Validate: should not be a date, contract number, or VIN
      if (_isValidInsuranceNumber(normalized, rawText)) {
        insuranceCandidates.add(normalized);
        if (kDebugMode) {
          debugPrint(
            'Insurance number candidate (spaced numeric): $normalized (raw: $candidate)',
          );
        }
      }
    }
  }

  // Try to find near labels
  final insuranceLabels = [
    'ATTESTATION D ASSURANCE',
    'ATTESTATION ASSURANCE',
    'N°',
    'NUMERO',
    'شهادة تأمين',
  ];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final normalizedLine = _normalizeForSearch(line);

    for (final label in insuranceLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label)) {
        // Check same line
        final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
        if (sameLineValue != null) {
          // Try letter+digit pattern
          final match = insurancePattern.firstMatch(
            sameLineValue.toUpperCase(),
          );
          if (match != null) {
            final candidate = match.group(0)!;
            if (!_isInsuranceLabel(candidate)) {
              insuranceCandidates.add(candidate);
              if (kDebugMode) {
                debugPrint(
                  'Insurance number candidate from same line after "$label": $candidate',
                );
              }
            }
          }

          // Try spaced numeric pattern
          final spacedMatch = spacedNumericPattern.firstMatch(sameLineValue);
          if (spacedMatch != null) {
            final candidate = spacedMatch.group(0)!;
            final normalized = candidate.replaceAll(RegExp(r'[\s\-]+'), '');
            if (_isValidInsuranceNumber(normalized, rawText)) {
              insuranceCandidates.add(normalized);
              if (kDebugMode) {
                debugPrint(
                  'Insurance number candidate (spaced) from same line after "$label": $normalized',
                );
              }
            }
          }
        }

        // Check next lines
        for (var j = i + 1; j < lines.length && j <= i + 3; j++) {
          final nextLine = lines[j].trim();

          // Try letter+digit pattern
          final match = insurancePattern.firstMatch(nextLine.toUpperCase());
          if (match != null) {
            final candidate = match.group(0)!;
            if (!_isInsuranceLabel(candidate)) {
              insuranceCandidates.add(candidate);
              if (kDebugMode) {
                debugPrint(
                  'Insurance number candidate from next line after "$label": $candidate',
                );
              }
            }
          }

          // Try spaced numeric pattern
          final spacedMatch = spacedNumericPattern.firstMatch(nextLine);
          if (spacedMatch != null) {
            final candidate = spacedMatch.group(0)!;
            final normalized = candidate.replaceAll(RegExp(r'[\s\-]+'), '');
            if (_isValidInsuranceNumber(normalized, rawText)) {
              insuranceCandidates.add(normalized);
              if (kDebugMode) {
                debugPrint(
                  'Insurance number candidate (spaced) from next line after "$label": $normalized',
                );
              }
            }
          }
        }
      }
    }
  }

  if (kDebugMode) {
    debugPrint('All insurance number candidates: $insuranceCandidates');
  }

  if (insuranceCandidates.isNotEmpty) {
    if (kDebugMode) {
      debugPrint('Selected insurance number: ${insuranceCandidates.first}');
    }
    return insuranceCandidates.first;
  }

  if (kDebugMode) {
    debugPrint('No insurance number found');
  }
  return null;
}

/// Validate if a numeric string is a valid insurance number
/// Excludes contract numbers, dates, phone numbers, VINs, and plate numbers
bool _isValidInsuranceNumber(String normalized, String rawText) {
  // Must be numeric only after normalization
  if (!RegExp(r'^\d+$').hasMatch(normalized)) return false;

  // Must be reasonable length (7-15 digits)
  if (normalized.length < 7 || normalized.length > 15) return false;

  // Exclude if it's a contract number (appears near "Contrat N°")
  if (rawText.toUpperCase().contains('CONTRAT') &&
      rawText.contains(normalized)) {
    final contractPattern = RegExp(
      'CONTRAT[^0-9]{0,10}$normalized',
      caseSensitive: false,
    );
    if (contractPattern.hasMatch(rawText)) {
      if (kDebugMode) {
        debugPrint('Rejected insurance number: looks like contract number');
      }
      return false;
    }
  }

  // Exclude if it looks like a date (8 digits in date format)
  if (normalized.length == 8 && _looksLikeCompactDate(normalized)) {
    if (kDebugMode) {
      debugPrint('Rejected insurance number: looks like date');
    }
    return false;
  }

  // Exclude if it looks like a phone number (starts with common prefixes)
  if (normalized.length >= 8 &&
      (normalized.startsWith('70') ||
          normalized.startsWith('71') ||
          normalized.startsWith('72') ||
          normalized.startsWith('73') ||
          normalized.startsWith('74') ||
          normalized.startsWith('75') ||
          normalized.startsWith('76') ||
          normalized.startsWith('77') ||
          normalized.startsWith('78') ||
          normalized.startsWith('79') ||
          normalized.startsWith('2') ||
          normalized.startsWith('9') ||
          normalized.startsWith('5') ||
          normalized.startsWith('216'))) {
    if (kDebugMode) {
      debugPrint('Rejected insurance number: looks like phone number');
    }
    return false;
  }

  return true;
}

/// Extract company name from insurance document OCR text
String? _insuranceExtractCompanyName(List<String> lines) {
  if (kDebugMode) {
    debugPrint('Company name extraction starting...');
  }

  final companyCandidates = <String>[];

  // Known Tunisian insurance companies (ordered by specificity - longer names first)
  final knownCompanies = [
    'BNA ASSURANCES',
    'AMI ASSURANCES',
    'ZITOUNA TAKAFUL',
    'TUNIS RE',
    'ATTIJARI ASSURANCE',
    'MAGHREBIA',
    'COTUNACE',
    'ATTIJARI',
    'ZITOUNA',
    'ASTREE',
    'COMAR',
    'LLOYD',
    'CARTE',
    'STAR',
    'BNA',
    'AMI',
    'GAT',
  ];

  // Noisy variants to reject if better match exists
  final noisyVariants = {'BNA LIOL', 'BNA SAG', 'BNA SA'};

  if (kDebugMode) {
    debugPrint('Searching for company name in ${lines.length} lines');
  }

  // FIRST: Search for known companies anywhere in the OCR text
  // Build a map of found companies with their match quality
  final foundCompanies = <String, int>{};

  for (final line in lines) {
    final cleaned = line.trim().toUpperCase();
    final normalized = _normalizeForSearch(cleaned);

    // Skip if it's a label
    if (_isInsuranceLabel(normalized)) {
      continue;
    }

    // Check if this line is or contains a known company
    for (final knownCompany in knownCompanies) {
      final normalizedCompany = _normalizeForSearch(knownCompany);

      // Exact match (highest priority)
      if (normalized == normalizedCompany) {
        foundCompanies[knownCompany] = 3;
        companyCandidates.add(cleaned);
        if (kDebugMode) {
          debugPrint(
            'Company candidate (exact match): $cleaned -> $knownCompany',
          );
        }
        break;
      }
      // Line contains company (medium priority)
      else if (normalized.contains(normalizedCompany)) {
        foundCompanies[knownCompany] = foundCompanies[knownCompany] ?? 2;
        if (!companyCandidates.contains(cleaned)) {
          companyCandidates.add(cleaned);
          if (kDebugMode) {
            debugPrint(
              'Company candidate (contains): $cleaned -> $knownCompany',
            );
          }
        }
        break;
      }
      // Company contains line (lower priority, for short names)
      else if (normalizedCompany.length > 3 &&
          normalizedCompany.contains(normalized) &&
          normalized.length >= 3) {
        foundCompanies[knownCompany] = foundCompanies[knownCompany] ?? 1;
        if (!companyCandidates.contains(cleaned)) {
          companyCandidates.add(cleaned);
          if (kDebugMode) {
            debugPrint(
              'Company candidate (partial): $cleaned -> $knownCompany',
            );
          }
        }
        break;
      }
    }
  }

  // Select the best company match
  // Prefer exact matches with longer company names, then by match quality
  if (foundCompanies.isNotEmpty) {
    // Sort by:
    // 1. Exact match (priority 3) first
    // 2. Then by company name length (longer = more specific)
    // 3. Then by match quality
    final sortedCompanies = foundCompanies.entries.toList()
      ..sort((a, b) {
        // First: prioritize exact matches (quality 3)
        if (a.value == 3 && b.value != 3) return -1;
        if (b.value == 3 && a.value != 3) return 1;

        // Second: compare by company name length (longer is better)
        final lengthCompare = b.key.length.compareTo(a.key.length);
        if (lengthCompare != 0) return lengthCompare;

        // Third: compare by match quality
        return b.value.compareTo(a.value);
      });

    final bestCompany = sortedCompanies.first.key;

    if (kDebugMode) {
      debugPrint(
        'Best matched company: $bestCompany (quality: ${sortedCompanies.first.value})',
      );
    }

    // Find the actual OCR line that matched this company
    // Prefer candidates that exactly match or contain the best company
    String? bestCandidate;
    int bestCandidateScore = 0;

    for (final candidate in companyCandidates) {
      final normalized = _normalizeForSearch(candidate);
      final normalizedBest = _normalizeForSearch(bestCompany);

      // Skip noisy variants if we have a better match
      if (noisyVariants.contains(candidate.toUpperCase()) &&
          bestCompany.length > candidate.length) {
        continue;
      }

      // Score candidates:
      // 3 = exact match
      // 2 = candidate contains best company
      // 1 = best company contains candidate
      int score = 0;
      if (normalized == normalizedBest) {
        score = 3;
      } else if (normalized.contains(normalizedBest)) {
        score = 2;
      } else if (normalizedBest.length > 3 &&
          normalizedBest.contains(normalized)) {
        score = 1;
      }

      if (score > bestCandidateScore) {
        bestCandidateScore = score;
        bestCandidate = candidate;
      }
    }

    if (bestCandidate != null) {
      if (kDebugMode) {
        debugPrint(
          'Selected company (known): $bestCandidate (matched: $bestCompany)',
        );
      }
      return bestCandidate;
    }

    // Fallback: return the known company name itself
    if (kDebugMode) {
      debugPrint('Selected company (known, fallback): $bestCompany');
    }
    return bestCompany;
  }

  // SECOND: Try label-neighbor extraction if no known company found
  final companyLabels = [
    'ENTREPRISE D ASSURANCE',
    'ENTREPRISE ASSURANCE',
    'COMPAGNIE',
    'ASSUREUR',
    'مؤسسة التأمين',
  ];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final normalizedLine = _normalizeForSearch(line);

    for (final label in companyLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label)) {
        // Check same line
        final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
        if (sameLineValue != null &&
            !_isInsuranceLabel(_normalizeForSearch(sameLineValue))) {
          companyCandidates.add(sameLineValue.trim().toUpperCase());
          if (kDebugMode) {
            debugPrint(
              'Company candidate from same line after "$label": ${sameLineValue.trim().toUpperCase()}',
            );
          }
        }

        // Check next lines
        for (var j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j].trim();
          final normalizedNext = _normalizeForSearch(nextLine);

          if (_isInsuranceLabel(normalizedNext)) {
            continue;
          }

          if (nextLine.length >= 3 && nextLine.length <= 50) {
            companyCandidates.add(nextLine.toUpperCase());
            if (kDebugMode) {
              debugPrint(
                'Company candidate from next line after "$label": ${nextLine.toUpperCase()}',
              );
            }
          }
        }
      }
    }
  }

  if (kDebugMode) {
    debugPrint('All company candidates: $companyCandidates');
  }

  if (companyCandidates.isNotEmpty) {
    if (kDebugMode) {
      debugPrint('Selected company: ${companyCandidates.first}');
    }
    return companyCandidates.first;
  }

  if (kDebugMode) {
    debugPrint('No company name found');
  }
  return null;
}

/// Extract policy holder name from insurance document OCR text
String? _insuranceExtractPolicyHolderName(List<String> lines) {
  if (kDebugMode) {
    debugPrint('Policy holder name extraction starting...');
  }

  final policyHolderLabels = [
    'NOM ET PRENOM',
    'NOM PRENOM',
    'RAISON SOCIALE',
    'ASSURE',
    'PARTICIPANT',
    'SOCIETAIRE',
    'المؤمن له',
    'المشترك',
  ];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final normalizedLine = _normalizeForSearch(line);

    for (final label in policyHolderLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label)) {
        // Check same line
        final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
        if (sameLineValue != null && _isLikelyName(sameLineValue)) {
          final normalized = _normalizeForSearch(sameLineValue);
          if (!_isInsuranceLabel(normalized)) {
            if (kDebugMode) {
              debugPrint(
                'Policy holder candidate from same line: ${sameLineValue.trim()}',
              );
            }
            return sameLineValue.trim().toUpperCase();
          }
        }

        // Check next lines
        for (var j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j].trim();
          if (_isLikelyName(nextLine)) {
            final normalized = _normalizeForSearch(nextLine);
            if (!_isInsuranceLabel(normalized)) {
              if (kDebugMode) {
                debugPrint(
                  'Policy holder candidate from next line: ${nextLine.toUpperCase()}',
                );
              }
              return nextLine.toUpperCase();
            }
          }
        }
      }
    }
  }

  if (kDebugMode) {
    debugPrint('No policy holder name found');
  }
  return null;
}

/// Extract policy type/usage from insurance document OCR text
String? _insuranceExtractPolicyType(List<String> lines) {
  if (kDebugMode) {
    debugPrint('Policy type extraction starting...');
  }

  final policyTypeCandidates = <String>[];

  // Known policy/usage types (ordered by specificity - longer first)
  final knownPolicyTypes = [
    'AFFAIRES ET PROMENADES',
    'TOUS DEPLACEMENTS',
    'USAGE PROFESSIONNEL',
    'USAGE PRIVE',
    'PROMENADES',
    'COMMERCIAL',
    'PERSONNEL',
    'AFFAIRES',
  ];

  // Labels that should not be confused with policy types
  final excludedLabels = {
    'USAGE',
    'TYPE',
    'CATEGORIE',
    'CLASSE',
    'CACHET',
    'SIGNATURE',
    'SIG',
  };

  if (kDebugMode) {
    debugPrint('Searching for policy type in ${lines.length} lines');
  }

  // FIRST: Search for known policy types anywhere in the OCR text
  for (final line in lines) {
    final cleaned = line.trim().toUpperCase();
    final normalized = _normalizeForSearch(cleaned);

    // Skip if it's a label or noise
    if (_isInsuranceLabel(normalized) || excludedLabels.contains(normalized)) {
      continue;
    }

    // Check if this line is or contains a known policy type
    for (final knownType in knownPolicyTypes) {
      final normalizedType = _normalizeForSearch(knownType);

      // Exact match
      if (normalized == normalizedType) {
        policyTypeCandidates.add(cleaned);
        if (kDebugMode) {
          debugPrint('Policy type candidate (exact): $cleaned');
        }
        break;
      }
      // Line contains policy type
      else if (normalized.contains(normalizedType)) {
        policyTypeCandidates.add(cleaned);
        if (kDebugMode) {
          debugPrint('Policy type candidate (contains): $cleaned');
        }
        break;
      }
      // Policy type contains line (for shorter types)
      else if (normalizedType.length > 5 &&
          normalizedType.contains(normalized) &&
          normalized.length >= 5) {
        policyTypeCandidates.add(cleaned);
        if (kDebugMode) {
          debugPrint('Policy type candidate (partial): $cleaned');
        }
        break;
      }
    }
  }

  // If we found known policy types, prefer the longest/most specific one
  if (policyTypeCandidates.isNotEmpty) {
    // Sort by length (longer = more specific)
    policyTypeCandidates.sort((a, b) => b.length.compareTo(a.length));

    if (kDebugMode) {
      debugPrint('Selected policy type (known): ${policyTypeCandidates.first}');
    }
    return policyTypeCandidates.first;
  }

  // SECOND: Try label-neighbor extraction
  final policyTypeLabels = ['USAGE', 'TYPE', 'CATEGORIE', 'الاستعمال'];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final normalizedLine = _normalizeForSearch(line);

    for (final label in policyTypeLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label)) {
        // Check same line
        final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
        if (sameLineValue != null &&
            sameLineValue.trim().length >= 3 &&
            !_isInsuranceLabel(_normalizeForSearch(sameLineValue)) &&
            !excludedLabels.contains(
              _normalizeForSearch(sameLineValue.trim()),
            )) {
          policyTypeCandidates.add(sameLineValue.trim().toUpperCase());
          if (kDebugMode) {
            debugPrint(
              'Policy type candidate from same line: ${sameLineValue.trim()}',
            );
          }
        }

        // Check next lines
        for (var j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j].trim();
          final normalizedNext = _normalizeForSearch(nextLine);

          if (_isInsuranceLabel(normalizedNext) ||
              excludedLabels.contains(normalizedNext)) {
            continue;
          }

          if (nextLine.length >= 3 && nextLine.length <= 50) {
            policyTypeCandidates.add(nextLine.toUpperCase());
            if (kDebugMode) {
              debugPrint(
                'Policy type candidate from next line: ${nextLine.toUpperCase()}',
              );
            }
          }
        }
      }
    }
  }

  if (kDebugMode) {
    debugPrint('All policy type candidates: $policyTypeCandidates');
  }

  if (policyTypeCandidates.isNotEmpty) {
    if (kDebugMode) {
      debugPrint('Selected policy type: ${policyTypeCandidates.first}');
    }
    return policyTypeCandidates.first;
  }

  if (kDebugMode) {
    debugPrint('No policy type found');
  }
  return null;
}

/// Extract contract number from insurance document OCR text
String? _insuranceExtractContractNumber(List<String> lines) {
  final contractLabels = [
    'CONTRAT N',
    'CONTRAT',
    'POLICE N',
    'POLICE',
    'عدد العقد',
  ];

  // Pattern: long numeric value
  final contractPattern = RegExp(r'\b\d{10,20}\b');

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final normalizedLine = _normalizeForSearch(line);

    for (final label in contractLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label)) {
        // Check same line
        final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
        if (sameLineValue != null) {
          final match = contractPattern.firstMatch(sameLineValue);
          if (match != null) return match.group(0);
        }

        // Check next lines
        for (var j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j];
          final match = contractPattern.firstMatch(nextLine);
          if (match != null) return match.group(0);
        }
      }
    }
  }

  return null;
}

/// Extract validity dates from insurance document OCR text
Map<String, String?> _insuranceExtractValidityDates(List<String> lines) {
  String? validFrom;
  String? validTo;

  final validityLabels = ['VALIDITE', 'PERIODE', 'الصلوحية'];
  final fromLabels = ['DU', 'DE', 'FROM', 'من'];
  final toLabels = ['AU', 'A', 'TO', 'إلى'];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final normalizedLine = _normalizeForSearch(line);

    // Check for validity section
    for (final label in validityLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label)) {
        // Look for dates in next few lines
        for (var j = i; j < lines.length && j <= i + 5; j++) {
          final checkLine = lines[j];
          final dates = _extractDates(checkLine);

          if (dates.length >= 2) {
            validFrom = dates[0];
            validTo = dates[1];
            break;
          } else if (dates.length == 1) {
            validFrom ??= dates[0];
            validTo ??= dates[0];
          }
        }
        break;
      }
    }

    // Check for "Du" / "From" labels
    for (final label in fromLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label) && validFrom == null) {
        final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
        if (sameLineValue != null) {
          final dates = _extractDates(sameLineValue);
          if (dates.isNotEmpty) validFrom = dates.first;
        }

        if (validFrom == null && i + 1 < lines.length) {
          final dates = _extractDates(lines[i + 1]);
          if (dates.isNotEmpty) validFrom = dates.first;
        }
      }
    }

    // Check for "Au" / "To" labels
    for (final label in toLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label) && validTo == null) {
        final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
        if (sameLineValue != null) {
          final dates = _extractDates(sameLineValue);
          if (dates.isNotEmpty) validTo = dates.first;
        }

        if (validTo == null && i + 1 < lines.length) {
          final dates = _extractDates(lines[i + 1]);
          if (dates.isNotEmpty) validTo = dates.first;
        }
      }
    }
  }

  return {'from': validFrom, 'to': validTo};
}

/// Extract vehicle brand from insurance document OCR text
String? _insuranceExtractVehicleBrand(List<String> lines) {
  final brandLabels = ['MARQUE', 'الصانع'];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final normalizedLine = _normalizeForSearch(line);

    for (final label in brandLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label)) {
        final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
        if (sameLineValue != null && sameLineValue.trim().length >= 2) {
          return sameLineValue.trim().toUpperCase();
        }

        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          if (nextLine.length >= 2 && nextLine.length <= 30) {
            return nextLine.toUpperCase();
          }
        }
      }
    }
  }

  return null;
}

/// Extract vehicle model from insurance document OCR text
String? _insuranceExtractVehicleModel(List<String> lines) {
  final modelLabels = ['TYPE', 'MODELE', 'النوع'];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final normalizedLine = _normalizeForSearch(line);

    for (final label in modelLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label)) {
        final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
        if (sameLineValue != null && sameLineValue.trim().isNotEmpty) {
          return sameLineValue.trim();
        }

        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          if (nextLine.isNotEmpty && nextLine.length <= 30) {
            return nextLine;
          }
        }
      }
    }
  }

  return null;
}

/// Extract vehicle VIN from insurance document OCR text
String? _insuranceExtractVehicleVin(List<String> lines) {
  final vinLabels = ['N SERIE', 'NUMERO SERIE', 'CHASSIS', 'العدد الرتبي'];

  // VIN pattern: 17 characters
  final vinPattern = RegExp(r'\b[A-HJ-NPR-Z0-9]{17}\b');

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final normalizedLine = _normalizeForSearch(line);

    for (final label in vinLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label)) {
        final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
        if (sameLineValue != null) {
          final match = vinPattern.firstMatch(sameLineValue.toUpperCase());
          if (match != null) return match.group(0);
        }

        if (i + 1 < lines.length) {
          final match = vinPattern.firstMatch(lines[i + 1].toUpperCase());
          if (match != null) return match.group(0);
        }
      }
    }
  }

  return null;
}

/// Extract vehicle plate from insurance document OCR text
String? _insuranceExtractVehiclePlate(List<String> lines) {
  final plateLabels = ['IMMATRICULATION', 'N IMMATRICULATION'];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final normalizedLine = _normalizeForSearch(line);

    for (final label in plateLabels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, label)) {
        final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
        if (sameLineValue != null && sameLineValue.trim().length >= 5) {
          return sameLineValue.trim();
        }

        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          if (nextLine.length >= 5 && nextLine.length <= 15) {
            return nextLine;
          }
        }
      }
    }
  }

  return null;
}

/// Check if a value is an insurance document label or noise
bool _isInsuranceLabel(String normalizedValue) {
  final labels = {
    'ATTESTATION',
    'ATTESTATION D ASSURANCE',
    'ATTESTATION ASSURANCE',
    'ASSURANCE',
    'ENTREPRISE',
    'ENTREPRISE D ASSURANCE',
    'COMPAGNIE',
    'CONTRAT',
    'POLICE',
    'VALIDITE',
    'PERIODE',
    'USAGE',
    'CATEGORIE',
    'CLASSE',
    'INTERMEDIAIRE',
    'IDENTIFICATION',
    'IDENTIFICATION DU VEHICULE',
    'VEHICULE',
    'MARQUE',
    'TYPE',
    'MODELE',
    'N SERIE',
    'NUMERO SERIE',
    'CHASSIS',
    'IMMATRICULATION',
    'PUISSANCE',
    'PUISSANCE FISCALE',
    'CYLINDREE',
    'CACHET',
    'SIGNATURE',
    'ASSURE',
    'PARTICIPANT',
    'SOCIETAIRE',
    'NOM ET PRENOM',
    'RAISON SOCIALE',
    'DU',
    'AU',
    'DE',
    'A',
  };

  return labels.contains(normalizedValue);
}

// ============================================================================
// Driver License Parsing Helper Functions (Existing - Do Not Modify)
// ============================================================================

final RegExp _datePattern = RegExp(
  r'\b(?:\d{1,2}\s*[./-]\s*\d{1,2}\s*[./-]\s*\d{2,4}|\d{4}\s*[./-]\s*\d{1,2}\s*[./-]\s*\d{1,2})\b',
);
final RegExp _looseDatePattern = RegExp(
  r'(?:\d{1,2}\s*[./-]\s*\d{1,2}\s*[./-]\s*\d{2,4}|\d{4}\s*[./-]\s*\d{1,2}\s*[./-]\s*\d{1,2})',
);
final RegExp _tunisianLicensePattern = RegExp(
  r'(?:^|[^A-Z0-9])([0-9OZ]{2})\s*([/\-:|]|\s+)\s*([0-9O]{5,6})(?=$|[^A-Z0-9])',
  caseSensitive: false,
);
final RegExp _mergedTunisianLicensePattern = RegExp(
  r'(?:^|[^A-Z0-9])([0-9OZ]{3})\s+([0-9O]{5,6})(?=$|[^A-Z0-9])',
  caseSensitive: false,
);

enum _TunisianLicenseLayout { oldFormat, newFormat }

const List<String> _supportedNumberedMarkers = [
  '1',
  '2',
  '3',
  '4a',
  '4b',
  '4c',
  '4d',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
];

_TunisianLicenseLayout _detectTunisianLicenseLayout(
  Map<String, String> fields,
  String rawText,
) {
  final hasNewFormatMarker =
      const {'4a', '4b', '4c', '4d'}.any(fields.containsKey) ||
      _numberedFieldMarkers(
        _normalizeOcrText(rawText),
      ).any((marker) => const {'4a', '4b', '4c', '4d'}.contains(marker.marker));

  return hasNewFormatMarker
      ? _TunisianLicenseLayout.newFormat
      : _TunisianLicenseLayout.oldFormat;
}

String? _normalizeMarker(String? value) {
  if (value == null) return null;

  final marker = value.toLowerCase().replaceAll(RegExp(r'[\s.\-:]+'), '');
  return _supportedNumberedMarkers.contains(marker) ? marker : null;
}

class _NumberedFieldMarker {
  const _NumberedFieldMarker({
    required this.marker,
    required this.markerStart,
    required this.valueStart,
  });

  final String marker;
  final int markerStart;
  final int valueStart;
}

class _NameFallback {
  const _NameFallback({this.firstName, this.lastName});

  final String? firstName;
  final String? lastName;
}

class _TunisianLicenseCandidate {
  const _TunisianLicenseCandidate({
    required this.raw,
    required this.normalized,
  });

  final String raw;
  final String normalized;
}

T? _firstOrNull<T>(List<T> values) => values.isEmpty ? null : values.first;

Map<String, String> _extractNumberedFields(String rawText, List<String> lines) {
  final fields = <String, String>{};

  for (final marker in _supportedNumberedMarkers) {
    final value = _extractNumberedField(rawText, marker);
    if (value != null) {
      _putNumberedField(fields, marker, value);
    }
  }

  for (var i = 0; i < lines.length; i++) {
    final line = _normalizeSpaces(lines[i]);
    if (line.isEmpty) continue;

    final segmentedFields = _numberedFieldsInLine(line);
    if (segmentedFields.isNotEmpty) {
      for (final entry in segmentedFields.entries) {
        _putNumberedField(fields, entry.key, entry.value);
      }
      continue;
    }

    final markerOnly = RegExp(
      r'^\s*(4\s*[\.\-:]?\s*[a-dA-D]|[1-9])\s*[\.\-:)]?\s*$',
    ).firstMatch(line);
    if (markerOnly == null || i + 1 >= lines.length) continue;

    final nextLine = _normalizeSpaces(lines[i + 1]);
    if (_startsWithNumberedField(nextLine)) continue;

    final marker = _normalizeMarker(markerOnly.group(1));
    if (marker != null) {
      _putNumberedField(fields, marker, nextLine);
    }
  }

  return fields;
}

String? _extractNumberedField(String text, String marker) {
  final normalizedText = _normalizeOcrText(text);
  final markers = _numberedFieldMarkers(normalizedText);

  for (var i = 0; i < markers.length; i++) {
    final fieldMarker = markers[i];
    if (fieldMarker.marker != marker) continue;

    final end = i + 1 < markers.length
        ? markers[i + 1].markerStart
        : normalizedText.length;
    final value = normalizedText.substring(fieldMarker.valueStart, end);
    final cleanedValue = _cleanNumberedValue(value);
    if (cleanedValue.isEmpty) continue;
    if (_isUsefulNumberedFieldValue(marker, cleanedValue)) {
      return cleanedValue;
    }
  }

  return null;
}

List<_NumberedFieldMarker> _numberedFieldMarkers(String text) {
  final markerPattern = RegExp(
    r'(^|[\n\s])(4\s*[\.\-:]?\s*[a-dA-D]|[1-9])(?:\s*[\.\-:)]\s*|\s+)(?=\S)',
  );

  return markerPattern.allMatches(text).map((match) {
    final prefix = match.group(1) ?? '';
    final marker = _normalizeMarker(match.group(2))!;
    return _NumberedFieldMarker(
      marker: marker,
      markerStart: match.start + prefix.length,
      valueStart: match.end,
    );
  }).toList();
}

Map<String, String> _numberedFieldsInLine(String line) {
  final fields = <String, String>{};
  final punctuatedMarker = RegExp(
    r'(^|\s)(4\s*[\.\-:]?\s*[a-dA-D]|[1-9])\s*[\.\-:)]\s*',
  );
  final markers = punctuatedMarker.allMatches(line).toList();

  if (markers.isNotEmpty) {
    for (var i = 0; i < markers.length; i++) {
      final marker = markers[i];
      final fieldMarker = _normalizeMarker(marker.group(2));
      if (fieldMarker == null) continue;

      final start = marker.end;
      final end = i + 1 < markers.length ? markers[i + 1].start : line.length;
      final value = line.substring(start, end);
      _putNumberedField(fields, fieldMarker, value);
    }

    return fields;
  }

  final lineStartField = RegExp(
    r'^\s*(4\s*[\.\-:]?\s*[a-dA-D]|[1-9])(?:\s+|\s*[\.\-:)]\s*)(.+)$',
  ).firstMatch(line);
  final fieldMarker = _normalizeMarker(lineStartField?.group(1));
  if (fieldMarker == null) return fields;

  _putNumberedField(fields, fieldMarker, lineStartField?.group(2) ?? '');
  return fields;
}

void _putNumberedField(
  Map<String, String> fields,
  String marker,
  String value,
) {
  final cleanedValue = _cleanNumberedValue(value);
  if (cleanedValue.isEmpty) return;

  final existingValue = fields[marker];
  if (existingValue == null ||
      (!_isUsefulNumberedFieldValue(marker, existingValue) &&
          _isUsefulNumberedFieldValue(marker, cleanedValue))) {
    fields[marker] = cleanedValue;
  }
}

bool _isUsefulNumberedFieldValue(String marker, String value) {
  final cleanedValue = _cleanNumberedValue(value);
  final minLength = marker == '8' || marker == '9' ? 1 : 2;
  if (cleanedValue.length < minLength) return false;
  if (_isDocumentKeyword(_normalizeForSearch(cleanedValue))) return false;
  return marker.trim().isNotEmpty;
}

bool _startsWithNumberedField(String line) {
  return RegExp(
    r'^\s*(?:4\s*[\.\-:]?\s*[a-dA-D]|[1-9])(?:\s*[\.\-:)]\s*|\s+|$)',
  ).hasMatch(line);
}

String _normalizeForSearch(String value) {
  return value
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(
        RegExp('[\u00e0\u00e1\u00e2\u00e3\u00e4\u00e5]', caseSensitive: false),
        'A',
      )
      .replaceAll(RegExp('[\u00e7]', caseSensitive: false), 'C')
      .replaceAll(
        RegExp('[\u00e8\u00e9\u00ea\u00eb]', caseSensitive: false),
        'E',
      )
      .replaceAll(
        RegExp('[\u00ec\u00ed\u00ee\u00ef]', caseSensitive: false),
        'I',
      )
      .replaceAll(RegExp('[\u00f1]', caseSensitive: false), 'N')
      .replaceAll(
        RegExp('[\u00f2\u00f3\u00f4\u00f5\u00f6]', caseSensitive: false),
        'O',
      )
      .replaceAll(
        RegExp('[\u00f9\u00fa\u00fb\u00fc]', caseSensitive: false),
        'U',
      )
      .replaceAll(RegExp('[\u00fd\u00ff]', caseSensitive: false), 'Y')
      .toUpperCase();
}

String _normalizeSpaces(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ');
}

String _normalizeOcrText(String value) {
  return value
      .split(RegExp(r'\r?\n'))
      .map(_normalizeSpaces)
      .where((line) => line.isNotEmpty)
      .join('\n');
}

String _cleanNumberedValue(String value) {
  return _cleanValue(
    value.replaceFirst(
      RegExp(r'^\s*(?:4\s*[\.\-:]?\s*[a-dA-D]|[1-9])(?:\s*[\.\-:)]\s*|\s+)'),
      '',
    ),
  );
}

String? _nameFromNumberedField(String? value) {
  if (value == null) return null;

  final cleanedName = _cleanNameValue(value);
  if (!_isLikelyName(cleanedName)) return null;
  return cleanedName;
}

String? _nameNearLabel(List<String> lines, List<String> labels) {
  final value = _valueNearLabel(lines, labels, (value) {
    final cleanedName = _cleanNameValue(value);
    return _isLikelyName(cleanedName);
  });

  return value == null ? null : _cleanNameValue(value);
}

_NameFallback _newLayoutNameFallback({
  required List<String> lines,
  required String? firstName,
  required String? lastName,
  required String? birthPlace,
}) {
  final candidates = _newLayoutNameCandidates(lines, birthPlace: birthPlace);

  if (kDebugMode) {
    debugPrint('Driver license name fallback candidates: $candidates');
  }

  if (candidates.length >= 2 && firstName == null && lastName == null) {
    return _NameFallback(lastName: candidates[0], firstName: candidates[1]);
  }

  return _NameFallback(
    firstName:
        firstName ??
        _candidateAfterAnchor(candidates, lastName, excluded: [birthPlace]),
    lastName:
        lastName ??
        _candidateBeforeAnchor(candidates, firstName, excluded: [birthPlace]),
  );
}

List<String> _newLayoutNameCandidates(
  List<String> lines, {
  required String? birthPlace,
}) {
  final candidates = <String>[];
  final normalizedBirthPlace = _normalizeForSearch(birthPlace ?? '');
  final topLines = lines.take(14).toList();

  for (var i = 0; i < topLines.length; i++) {
    final rawLine = topLines[i];
    final cleanedLine = _cleanNameValue(rawLine);
    final normalizedLine = _normalizeForSearch(cleanedLine);
    final nextLineHasDate =
        i + 1 < topLines.length && _extractDates(topLines[i + 1]).isNotEmpty;

    if (normalizedBirthPlace.isNotEmpty &&
        normalizedLine == normalizedBirthPlace) {
      continue;
    }

    if (!_isLikelyNewLayoutNameLine(
      rawLine: rawLine,
      cleanedLine: cleanedLine,
      followedByDate: nextLineHasDate,
    )) {
      continue;
    }

    if (candidates.any(
      (candidate) => _sameNormalizedValue(candidate, cleanedLine),
    )) {
      continue;
    }

    candidates.add(cleanedLine);
    if (candidates.length == 4) break;
  }

  return candidates;
}

bool _isLikelyNewLayoutNameLine({
  required String rawLine,
  required String cleanedLine,
  required bool followedByDate,
}) {
  if (followedByDate) return false;
  if (_extractDates(rawLine).isNotEmpty) return false;
  if (_tunisianLicenseCandidates(rawLine).isNotEmpty) return false;
  if (_nationalIdCandidatesFromText(rawLine).isNotEmpty) return false;
  if (RegExp(r'[.:/\\]').hasMatch(cleanedLine)) return false;
  if (!RegExp(r'[A-Za-z\u0600-\u06FF]').hasMatch(cleanedLine)) return false;
  return _isLikelyName(cleanedLine);
}

String? _candidateBeforeAnchor(
  List<String> candidates,
  String? anchor, {
  List<String?> excluded = const [],
}) {
  final anchorIndex = _candidateIndex(candidates, anchor);
  if (anchorIndex <= 0) return null;

  for (var i = anchorIndex - 1; i >= 0; i--) {
    final candidate = candidates[i];
    if (_candidateExcluded(candidate, excluded)) continue;
    return candidate;
  }

  return null;
}

String? _candidateAfterAnchor(
  List<String> candidates,
  String? anchor, {
  List<String?> excluded = const [],
}) {
  final anchorIndex = _candidateIndex(candidates, anchor);
  if (anchorIndex == -1 || anchorIndex >= candidates.length - 1) return null;

  for (var i = anchorIndex + 1; i < candidates.length; i++) {
    final candidate = candidates[i];
    if (_candidateExcluded(candidate, excluded)) continue;
    return candidate;
  }

  return null;
}

int _candidateIndex(List<String> candidates, String? anchor) {
  if (anchor == null || anchor.trim().isEmpty) return -1;
  return candidates.indexWhere(
    (candidate) => _sameNormalizedValue(candidate, anchor),
  );
}

bool _candidateExcluded(String candidate, List<String?> excluded) {
  return excluded
      .where((value) => value != null && value.trim().isNotEmpty)
      .any((value) => _sameNormalizedValue(candidate, value!));
}

bool _sameNormalizedValue(String left, String right) {
  return _normalizeForSearch(left) == _normalizeForSearch(right);
}

String _cleanNameValue(String value) {
  final withoutLabels = _stripLeadingLabels(value, const [
    'NOM ET PRENOM',
    'NOM PRENOM',
    'FULL NAME',
    'NAME',
    'NOM',
    'PRENOM',
    'PRENOMS',
    'SURNAME',
    'LAST NAME',
    'FAMILY NAME',
    'FIRST NAME',
    'GIVEN NAME',
    '\u0627\u0644\u0627\u0633\u0645 \u0627\u0644\u0643\u0627\u0645\u0644',
    '\u0627\u0644\u0644\u0642\u0628',
    '\u0627\u0644\u0627\u0633\u0645',
  ]);

  return _cleanValue(withoutLabels.replaceAll(_datePattern, ''));
}

String? _placeFromDateField(String? value) {
  if (value == null) return null;

  final place = _cleanValue(value.replaceAll(_datePattern, ''));
  if (place.length < 2) return null;
  if (_isDocumentKeyword(_normalizeForSearch(place))) return null;
  return place;
}

String? _plainTextFromNumberedField(String? value) {
  if (value == null) return null;

  final cleanedValue = _cleanNumberedValue(value);
  if (cleanedValue.length < 2) return null;
  if (_isDocumentKeyword(_normalizeForSearch(cleanedValue))) return null;
  return cleanedValue;
}

String? _categoryFromNumberedField(String? value) {
  final cleanedValue = _plainTextFromNumberedField(value);
  if (cleanedValue == null) return null;

  final compactCategory = cleanedValue
      .replaceAll(RegExp(r'[^A-Za-z0-9/+-]+'), ' ')
      .trim();
  return compactCategory.isEmpty ? null : compactCategory;
}

String? _valueNearLabel(
  List<String> lines,
  List<String> labels,
  bool Function(String value) isUseful,
) {
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final normalizedLine = _normalizeForSearch(line);
    String? label;
    for (final candidateLabel in labels.map(_normalizeForSearch)) {
      if (_containsLabel(normalizedLine, candidateLabel)) {
        label = candidateLabel;
        break;
      }
    }

    if (label == null) continue;

    final sameLineValue = _valueAfterLabel(line, normalizedLine, label);
    if (sameLineValue != null && isUseful(sameLineValue)) {
      return _cleanValue(sameLineValue);
    }

    for (
      var nextIndex = i + 1;
      nextIndex < lines.length && nextIndex <= i + 2;
      nextIndex++
    ) {
      final nextLine = lines[nextIndex];
      if (isUseful(nextLine)) return _cleanValue(nextLine);
    }
  }

  return null;
}

bool _containsLabel(String normalizedLine, String label) {
  return RegExp(
    '(^|[^A-Z0-9])${RegExp.escape(label)}([^A-Z0-9]|\$)',
  ).hasMatch(normalizedLine);
}

String? _valueAfterLabel(
  String originalLine,
  String normalizedLine,
  String normalizedLabel,
) {
  final labelIndex = normalizedLine.indexOf(normalizedLabel);
  if (labelIndex == -1) return null;

  final valueStart = labelIndex + normalizedLabel.length;
  if (valueStart >= originalLine.length) return null;

  final value = originalLine
      .substring(valueStart)
      .replaceFirst(RegExp(r'^[\s:\-#/().]+'), '');

  return value.trim().isEmpty ? null : value.trim();
}

String _stripLeadingLabels(String value, List<String> labels) {
  var cleaned = _cleanNumberedValue(value);

  for (final label in labels) {
    final normalizedLabel = _normalizeForSearch(label);
    final normalizedValue = _normalizeForSearch(cleaned);
    if (!_containsLabelAtStart(normalizedValue, normalizedLabel)) continue;

    final labelLength = normalizedLabel.length.clamp(0, cleaned.length).toInt();
    cleaned = cleaned.substring(labelLength);
    cleaned = _cleanValue(cleaned);
  }

  return cleaned;
}

bool _containsLabelAtStart(String normalizedValue, String normalizedLabel) {
  if (!normalizedValue.startsWith(normalizedLabel)) return false;
  if (normalizedValue.length == normalizedLabel.length) return true;

  final nextCharacter = normalizedValue.substring(
    normalizedLabel.length,
    normalizedLabel.length + 1,
  );
  return !RegExp(r'[A-Z0-9]').hasMatch(nextCharacter);
}

List<String> _extractDates(String text) {
  final matches = _datePattern.allMatches(text);
  return matches
      .map((match) => _normalizeDate(match.group(0)))
      .whereType<String>()
      .toSet()
      .toList();
}

String? _normalizeDate(String? value) {
  if (value == null) return null;
  return value
      .trim()
      .replaceAllMapped(RegExp(r'\s*([./-])\s*'), (match) => match.group(1)!)
      .replaceAll(RegExp(r'\s+'), ' ');
}

String? _dateFromText(String? text) {
  if (text == null) return null;

  final dates = _extractDates(text);
  return dates.isEmpty ? null : dates.first;
}

String? _dateNearLabel(List<String> lines, List<String> labels) {
  final value = _valueNearLabel(
    lines,
    labels,
    (value) => _extractDates(value).isNotEmpty,
  );

  final dates = value == null ? const <String>[] : _extractDates(value);
  return dates.isEmpty ? null : dates.first;
}

String? _licenseNearLabel(List<String> lines) {
  final labeledValue = _valueNearLabel(lines, const [
    'NUMERO DE PERMIS',
    'NUMERO PERMIS',
    'NO DE PERMIS',
    'N DE PERMIS',
    'PERMIS',
    'DRIVING LICENSE',
    'LICENCE',
    'LICENSE',
    'NO',
    'N',
    'LICENSE NO',
    'LICENSE NUMBER',
    'NUMERO',
    'NUMBER',
    '\u0631\u062e\u0635\u0629',
    '\u0631\u0642\u0645',
  ], (value) => _licenseFromLabeledValue(value) != null);

  return labeledValue == null ? null : _licenseFromLabeledValue(labeledValue);
}

String? _licenseFromNumberedField(String? value) {
  if (value == null) return null;
  final cleanedValue = _removeTrailingFieldMarkerNoise(value);
  return _tunisianLicenseFromText(cleanedValue) ??
      _tunisianLicenseFromLooseValue(cleanedValue) ??
      _licenseCandidateFromValue(cleanedValue);
}

String? _licenseFromLabeledValue(String value) {
  final cleanedValue = _stripLeadingLabels(value, const [
    'NUMERO DE PERMIS',
    'NUMERO PERMIS',
    'NO DE PERMIS',
    'N DE PERMIS',
    'PERMIS',
    'DRIVING LICENSE',
    'LICENCE',
    'LICENSE',
    'NO',
    'N',
    'LICENSE NO',
    'LICENSE NUMBER',
    'NUMERO',
    'NUMBER',
  ]);

  return _tunisianLicenseFromText(cleanedValue) ??
      _tunisianLicenseFromLooseValue(cleanedValue) ??
      _licenseCandidateFromValue(cleanedValue);
}

List<String> _tunisianLicenseCandidates(String text) {
  return _rawTunisianLicenseCandidates(
    text,
  ).map((candidate) => candidate.normalized).toSet().toList();
}

List<_TunisianLicenseCandidate> _rawTunisianLicenseCandidates(
  String text, {
  List<String> excludedCompactValues = const [],
}) {
  final sanitizedText = text.replaceAll(_looseDatePattern, ' ');
  final compactExclusions = excludedCompactValues
      .map((value) => value.replaceAll(RegExp(r'\D'), ''))
      .where((value) => value.length == 8)
      .toSet();
  final strongCandidates = <_TunisianLicenseCandidate>[];
  final weakCandidates = <_TunisianLicenseCandidate>[];
  final mergedPrefixCandidates = <_TunisianLicenseCandidate>[];

  for (final match in _tunisianLicensePattern.allMatches(sanitizedText)) {
    final prefix = match.group(1);
    final separator = match.group(2);
    final serial = match.group(3);
    final normalized = _normalizeTunisianLicenseParts(prefix, serial);
    if (normalized == null) continue;

    final compactLicense = normalized.replaceAll('/', '');
    if (compactExclusions.contains(compactLicense)) continue;
    if (_looksLikeCompactDate(compactLicense)) continue;

    final raw = _cleanValue(
      (match.group(0) ?? '').replaceFirst(RegExp(r'^[^A-Z0-9]+'), ''),
    );
    final hasStrongSeparator = separator != null && separator.trim().isNotEmpty
        ? RegExp(r'[/\-:|]').hasMatch(separator)
        : false;
    final candidate = _TunisianLicenseCandidate(
      raw: raw,
      normalized: normalized,
    );
    final targetList = hasStrongSeparator ? strongCandidates : weakCandidates;
    if (!targetList.any((item) => item.normalized == normalized)) {
      targetList.add(candidate);
    }
  }

  for (final match in _mergedTunisianLicensePattern.allMatches(sanitizedText)) {
    final prefix = match.group(1);
    final serial = match.group(2);
    final normalized = _normalizeMergedTunisianLicenseParts(prefix, serial);
    if (normalized == null) continue;

    final compactLicense = normalized.replaceAll('/', '');
    if (compactExclusions.contains(compactLicense)) continue;
    if (_looksLikeCompactDate(compactLicense)) continue;

    final raw = _cleanValue(
      (match.group(0) ?? '').replaceFirst(RegExp(r'^[^A-Z0-9]+'), ''),
    );
    final candidate = _TunisianLicenseCandidate(
      raw: raw,
      normalized: normalized,
    );
    final candidateAlreadyFound = [
      ...strongCandidates,
      ...weakCandidates,
      ...mergedPrefixCandidates,
    ].any((item) => item.normalized == normalized);
    if (!candidateAlreadyFound) {
      mergedPrefixCandidates.add(candidate);
    }
  }

  return [...strongCandidates, ...weakCandidates, ...mergedPrefixCandidates];
}

String? _normalizeTunisianLicenseParts(String? prefix, String? serial) {
  if (prefix == null || serial == null) return null;

  final normalizedPrefix = prefix
      .toUpperCase()
      .replaceAll('O', '0')
      .replaceAll('Z', '2');
  final normalizedSerial = serial.toUpperCase().replaceAll('O', '0');

  if (!RegExp(r'^\d{2}$').hasMatch(normalizedPrefix)) return null;
  if (!RegExp(r'^\d{5,6}$').hasMatch(normalizedSerial)) return null;

  return '$normalizedPrefix/${normalizedSerial.padLeft(6, '0')}';
}

String? _normalizeMergedTunisianLicenseParts(String? prefix, String? serial) {
  if (prefix == null || prefix.length != 3) return null;

  return _normalizeTunisianLicenseParts(prefix.substring(0, 2), serial);
}

String? _tunisianLicenseFromText(String text) {
  return _firstOrNull(_tunisianLicenseCandidates(text));
}

String? _tunisianLicenseFromLooseValue(String value) {
  return _tunisianLicenseFromText(value);
}

String? _licenseCandidateFromValue(String value) {
  final searchableValue = _normalizeForSearch(
    value.replaceAll(_datePattern, ' '),
  );

  final matches = RegExp(
    r'\b[A-Z0-9]+(?:\s*[/-]\s*[A-Z0-9]+|\s+[A-Z0-9]+)*\b',
  ).allMatches(searchableValue);

  for (final match in matches) {
    final candidate = _cleanLicenseNumber(match.group(0));
    if (candidate == null) continue;
    if (_isLikelyLicenseNumber(candidate)) return candidate;
  }

  return null;
}

String _removeTrailingFieldMarkerNoise(String value) {
  return value
      .replaceAll(_datePattern, ' ')
      .replaceFirst(RegExp(r'\s+(?:4\s*[\.\-:]?\s*[a-dA-D]|[2-9])\s*$'), '')
      .trim();
}

String? _cleanLicenseNumber(String? value) {
  if (value == null) return null;

  final cleaned = value
      .trim()
      .replaceAllMapped(RegExp(r'\s*([/-])\s*'), (match) => match.group(1)!)
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[^A-Z0-9]+|[^A-Z0-9]+$'), '');

  return cleaned.isEmpty ? null : cleaned;
}

String? _nationalIdFromNumberedField(String? value) {
  if (value == null) return null;
  return _nationalIdCandidateFromValue(value);
}

String? _nationalIdNearLabel(List<String> lines) {
  final labeledValue = _valueNearLabel(lines, const [
    'CIN',
    'NATIONAL ID',
    'NATIONAL IDENTITY',
    'ID NUMBER',
    'IDENTITY NUMBER',
    'CARTE IDENTITE',
    'CARTE D IDENTITE',
    '\u0628\u0637\u0627\u0642\u0629 \u062a\u0639\u0631\u064a\u0641',
    '\u0631\u0642\u0645 \u0627\u0644\u0628\u0637\u0627\u0642\u0629',
  ], (value) => _nationalIdCandidateFromValue(value) != null);

  return labeledValue == null
      ? null
      : _nationalIdCandidateFromValue(labeledValue);
}

String? _nationalIdCandidateFromValue(String value) {
  final cleanedValue = _stripLeadingLabels(value, const [
    'CIN',
    'NATIONAL ID',
    'NATIONAL IDENTITY',
    'ID NUMBER',
    'IDENTITY NUMBER',
    'CARTE IDENTITE',
    'CARTE D IDENTITE',
  ]);

  return _firstOrNull(_nationalIdCandidatesFromText(cleanedValue));
}

List<String> _nationalIdCandidatesFromText(String text) {
  final sanitized = _textWithoutDatesAndLicenses(text);
  final candidates = <String>[];

  final matches = RegExp(
    r'(?:^|[^\d])(\d{8})(?=$|[^\d])',
  ).allMatches(sanitized);

  for (final match in matches) {
    final candidate = match.group(1);
    if (candidate == null || !_isLikelyNationalId(candidate)) continue;
    if (!candidates.contains(candidate)) {
      candidates.add(candidate);
    }
  }

  return candidates;
}

String _textWithoutDatesAndLicenses(String text) {
  return text
      .replaceAll(_tunisianLicensePattern, ' ')
      .replaceAll(_looseDatePattern, ' ');
}

bool _isLikelyNationalId(String candidate) {
  if (!RegExp(r'^\d{8}$').hasMatch(candidate)) return false;
  return !_looksLikeCompactDate(candidate);
}

bool _looksLikeCompactDate(String value) {
  if (!RegExp(r'^\d{8}$').hasMatch(value)) return false;

  final dayFirstDay = int.tryParse(value.substring(0, 2));
  final dayFirstMonth = int.tryParse(value.substring(2, 4));
  final dayFirstYear = int.tryParse(value.substring(4, 8));
  if (_isValidDateParts(dayFirstDay, dayFirstMonth, dayFirstYear)) {
    return true;
  }

  final yearFirstYear = int.tryParse(value.substring(0, 4));
  final yearFirstMonth = int.tryParse(value.substring(4, 6));
  final yearFirstDay = int.tryParse(value.substring(6, 8));
  return _isValidDateParts(yearFirstDay, yearFirstMonth, yearFirstYear);
}

bool _isValidDateParts(int? day, int? month, int? year) {
  if (day == null || month == null || year == null) return false;
  if (year < 1900 || year > 2099) return false;
  if (month < 1 || month > 12) return false;
  if (day < 1 || day > 31) return false;
  return true;
}

bool _isLikelyName(String value) {
  final cleaned = _cleanValue(value);
  final normalized = _normalizeForSearch(cleaned);
  if (cleaned.length < 2) return false;
  if (RegExp(r'\d').hasMatch(cleaned)) return false;
  if (RegExp(r'[./\\]').hasMatch(cleaned)) return false;
  if (cleaned.split(RegExp(r'\s+')).length > 5) return false;
  return !_isDocumentKeyword(normalized);
}

bool _isLikelyLicenseNumber(String candidate) {
  final normalized = _normalizeForSearch(candidate);
  final digits = normalized.replaceAll(RegExp(r'\D'), '');
  if (normalized.length < 5 || normalized.length > 18) return false;
  if (digits.length < 4) return false;
  return !_isDocumentKeyword(normalized);
}

bool _isDocumentKeyword(String normalizedValue) {
  const keywords = [
    'PERMIS',
    'CONDUIRE',
    'DRIVING',
    'LICENSE',
    'LICENCE',
    'REPUBLIQUE',
    'REPUBLIC',
    'TUNISIENNE',
    'MINISTERE',
    'MINISTRY',
    'TRANSPORT',
    'AGENCE',
    'AGENCY',
    'AUTORITE',
    'AUTHORITY',
    'SIGNATURE',
    'ROYAUME',
    'KINGDOM',
    'MAROC',
    'MOROCCO',
    'FRANCE',
    'ALGERIE',
    'TUNISIE',
    'CARTE',
    'DATE',
    'BIRTH',
    'NAISSANCE',
    'VALIDITE',
    'EXPIRATION',
    'CATEGORIES',
    'CATEGORIE',
    '\u062c\u0645\u0647\u0648\u0631\u064a\u0629',
    '\u062a\u0648\u0646\u0633\u064a\u0629',
    '\u062a\u0648\u0646\u0633',
    '\u0631\u062e\u0635\u0629',
    '\u0633\u064a\u0627\u0642\u0629',
    '\u0627\u0644\u0635\u0646\u0641',
    '\u0648\u0632\u0627\u0631\u0629',
  ];

  return keywords.any(normalizedValue.contains);
}

String _cleanValue(String value) {
  return value
      .replaceFirst(RegExp(r'^[\s:\-#/().]+'), '')
      .replaceFirst(RegExp(r'[\s:\-#/().]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String? _combineName(String? firstName, String? lastName) {
  final combined = [
    firstName?.trim(),
    lastName?.trim(),
  ].where((part) => part != null && part.isNotEmpty).join(' ');

  return combined.isEmpty ? null : combined;
}
