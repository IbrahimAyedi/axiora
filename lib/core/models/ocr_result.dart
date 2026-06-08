/// Three-tier confidence label shown to the user after OCR extraction.
enum OcrConfidenceLevel {
  good,   // score >= 70 — most fields detected, result is reliable
  medium, // score 40-69 — partial detection, user should review carefully
  weak,   // score <  40 — very few fields detected, likely needs manual input
}

// raw result mte3 OCR text recognition

class OcrTextResult {
  final String rawText;
  final List<String> lines;
  final DateTime processedAt;

  OcrTextResult({
    required this.rawText,
    required this.lines,
    required this.processedAt,
  });
}

/// Structured vehicle document data extracted from OCR
class VehicleDocumentData {
  final String? ownerName;
  final String? plateNumber;
  final String? vin;
  final String? registrationNumber;
  final String? brand;
  final String? model;
  final String? registrationDate;
  final String? rawText;
  final double confidence; // 0.0 to 1.0
// data mte3 carte grise extracted mel OCR

  VehicleDocumentData({
    this.ownerName,
    this.plateNumber,
    this.vin,
    this.registrationNumber,
    this.brand,
    this.model,
    this.registrationDate,
    this.rawText,
    this.confidence = 0.0,
  });
  // true ken ma fama hatta data importante extracted
  bool get isEmpty =>
      ownerName == null &&
      plateNumber == null &&
      vin == null &&
      registrationNumber == null;

  /// Translates the 0.0-1.0 [confidence] float to a three-tier label.
  OcrConfidenceLevel get confidenceLevel {
    final score = (confidence * 100).round();
    if (score >= 70) return OcrConfidenceLevel.good;
    if (score >= 40) return OcrConfidenceLevel.medium;
    return OcrConfidenceLevel.weak;
  }

  /// Returns true when [vin] looks structurally valid (17 chars, no I/O/Q).
  bool get isVinValid {
    if (vin == null || vin!.length != 17) return false;
    return RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(vin!);
  }

  /// Returns true when [registrationDate] contains a four-digit year between
  /// 1980 and the current year (inclusive).
  bool get isRegistrationDatePlausible {
    if (registrationDate == null) return false;
    final yearMatch = RegExp(r'\b(19[89]\d|20\d{2})\b').firstMatch(registrationDate!);
    if (yearMatch == null) return false;
    final year = int.tryParse(yearMatch.group(1)!);
    return year != null && year >= 1980 && year <= DateTime.now().year;
  }

  @override
  String toString() =>
      'VehicleDocumentData(name: $ownerName, plate: $plateNumber, vin: $vin)';
}

// data mte3 permis extracted mel OCR
class DriverLicenseData {
  final String? fullName;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final String? birthPlace;
  // license info
  final String? licenseNumber;
  final String? nationalId;
  final String? issueDate;
  final String? issuingCountry;
  final String? issuingAuthority;
  final String? expiryDate;
  final String? address;
  final String? category;
  final String? rawText;
  final double confidence; // 0.0 to 1.0

  DriverLicenseData({
    this.fullName,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.birthPlace,
    this.licenseNumber,
    this.nationalId,
    this.issueDate,
    this.issuingCountry,
    this.issuingAuthority,
    this.expiryDate,
    this.address,
    this.category,
    this.rawText,
    this.confidence = 0.0,
  });
  // displayName yrajja3 fullName ken mawjoud, otherwise yjamma3 firstName w lastName
  String? get displayName {
    final explicitName = fullName?.trim();
    if (explicitName != null && explicitName.isNotEmpty) {
      return explicitName;
    }

    final combined = [
      firstName?.trim(),
      lastName?.trim(),
    ].where((part) => part != null && part.isNotEmpty).join(' ');

    return combined.isEmpty ? null : combined;
  }
  // true ken ma fama hatta data importante extracted
  bool get isEmpty =>
      displayName == null && licenseNumber == null && nationalId == null;

  /// Translates the 0.0-1.0 [confidence] float to a three-tier label.
  OcrConfidenceLevel get confidenceLevel {
    final score = (confidence * 100).round();
    if (score >= 70) return OcrConfidenceLevel.good;
    if (score >= 40) return OcrConfidenceLevel.medium;
    return OcrConfidenceLevel.weak;
  }

  /// Returns true when [licenseNumber] is non-empty.
  bool get isLicenseNumberPresent =>
      licenseNumber != null && licenseNumber!.trim().isNotEmpty;

  /// Returns true when [dateOfBirth] matches a common date pattern.
  bool get isDateOfBirthValid {
    if (dateOfBirth == null) return false;
    return RegExp(
      r'\b\d{1,2}[./-]\d{1,2}[./-]\d{2,4}\b',
    ).hasMatch(dateOfBirth!);
  }

  /// Returns true when [expiryDate] matches a common date pattern.
  bool get isExpiryDateValid {
    if (expiryDate == null) return false;
    return RegExp(
      r'\b\d{1,2}[./-]\d{1,2}[./-]\d{2,4}\b',
    ).hasMatch(expiryDate!);
  }

  @override
  String toString() =>
      'DriverLicenseData(name: $displayName, license: $licenseNumber, nationalId: $nationalId)';
}


/// // data mte3 assurance extracted mel OCR
class InsuranceDocumentData {
  final String? insuranceNumber;
  final String? companyName;
  final String? policyHolderName;
  final String? policyType;
  final String? contractNumber;
  final String? validFrom;
  final String? validTo;
  final String? vehiclePlate;
  final String? vin;
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? rawText;
  final double confidence; // 0.0 to 1.0

  InsuranceDocumentData({
    this.insuranceNumber,
    this.companyName,
    this.policyHolderName,
    this.policyType,
    this.contractNumber,
    this.validFrom,
    this.validTo,
    this.vehiclePlate,
    this.vin,
    this.vehicleBrand,
    this.vehicleModel,
    this.rawText,
    this.confidence = 0.0,
  });
  // true ken ma fama hatta data importante extracted
  bool get isEmpty =>
      insuranceNumber == null &&
      companyName == null &&
      policyHolderName == null &&
      policyType == null;

  /// Translates the 0.0-1.0 [confidence] float to a three-tier label.
  OcrConfidenceLevel get confidenceLevel {
    final score = (confidence * 100).round();
    if (score >= 70) return OcrConfidenceLevel.good;
    if (score >= 40) return OcrConfidenceLevel.medium;
    return OcrConfidenceLevel.weak;
  }

  /// Returns true when both [validFrom] and [validTo] contain date patterns
  /// and [validTo] appears to come after [validFrom].
  bool get areDatesConsistent {
    if (validFrom == null || validTo == null) return false;
    final datePattern = RegExp(r'\b(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})\b');
    final fromMatch = datePattern.firstMatch(validFrom!);
    final toMatch = datePattern.firstMatch(validTo!);
    if (fromMatch == null || toMatch == null) return false;
    // Parse in a best-effort way; year is the last group
    int? parseYear(RegExpMatch m) {
      final raw = m.group(3)!;
      final y = int.tryParse(raw);
      return (y != null && y < 100) ? 2000 + y : y;
    }
    final fromYear = parseYear(fromMatch);
    final toYear = parseYear(toMatch);
    if (fromYear == null || toYear == null) return true; // can't verify
    return toYear >= fromYear;
  }

  /// Returns true when [insuranceNumber] is non-empty.
  bool get isInsuranceNumberPresent =>
      insuranceNumber != null && insuranceNumber!.trim().isNotEmpty;

  @override
  String toString() =>
      'InsuranceDocumentData(insuranceNumber: $insuranceNumber, company: $companyName, policyHolder: $policyHolderName)';
}
