import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../utils/ocr_date_parser.dart';

final firebaseAuthUserProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

final appSessionProvider =
    NotifierProvider<AppSessionNotifier, AppSessionState>(
      AppSessionNotifier.new,
    );

class AppSessionNotifier extends Notifier<AppSessionState> {
  @override
  AppSessionState build() {
    final authState = ref.watch(firebaseAuthUserProvider);
    final now = DateTime.now();
    final authUser =
        authState.asData?.value ?? FirebaseAuth.instance.currentUser;

    final initialUser = UserProfile(
      id: authUser?.uid ?? '',
      email: authUser?.email ?? '',
      fullName: authUser?.displayName,
      phoneNumber: authUser?.phoneNumber,
      preferredLanguage: 'fr',
      isEmailVerified: authUser?.emailVerified ?? false,
      createdAt: now,
      updatedAt: now,
    );

    final initialState = AppSessionState(
      currentUser: initialUser,
      scans: const <DocumentScan>[],
      constats: const <Constat>[],
    );

    if (authUser != null) {
      Future<void>(() async {
        await _hydrateCurrentUserFromFirestore(authUser.uid);
        await _loadConstatsFromFirestore(authUser.uid);
        await _loadScansFromFirestore(authUser.uid);
      });
    }

    return initialState;
  }

  Future<void> _hydrateCurrentUserFromFirestore(String uid) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null || authUser.uid != uid) return;

    final currentUser = state.currentUser;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!snapshot.exists) {
        state = state.copyWith(
          currentUser: currentUser.copyWith(
            id: authUser.uid,
            email: authUser.email ?? currentUser.email,
            fullName: authUser.displayName ?? currentUser.fullName,
            phoneNumber: authUser.phoneNumber ?? currentUser.phoneNumber,
            isEmailVerified: authUser.emailVerified,
            updatedAt: currentUser.updatedAt,
          ),
        );
        return;
      }

      final data = snapshot.data()!;
      final firstName = _stringOrNull(data['firstName']);
      final lastName = _stringOrNull(data['lastName']);
      final firestoreEmail = _stringOrNull(data['email']);
      final phone = _stringOrNull(data['phone']);
      final insuranceNumber = _stringOrNull(data['insuranceNumber']);
      final insuranceId = _stringOrNull(data['insuranceId']);
      final contractNumber = _stringOrNull(data['contractNumber']);
      final agencyCode = _stringOrNull(data['agencyCode']);
      final role = _stringOrNull(data['role']);

      final fullName = [
        firstName,
        lastName,
      ].whereType<String>().where((value) => value.isNotEmpty).join(' ');

      InsuranceProfile? insuranceProfile;
      if (insuranceId != null || contractNumber != null || agencyCode != null) {
        insuranceProfile = InsuranceProfile(
          id: insuranceId ?? 'insurance_$uid',
          userId: uid,
          insuranceNumber: contractNumber ?? '',
          companyName: agencyCode ?? '',
          isPrimary: true,
          verificationStatus: ProfileVerificationStatus.unverified,
          createdAt: currentUser.createdAt,
          updatedAt: currentUser.updatedAt,
        );
      }

      state = state.copyWith(
        currentUser: currentUser.copyWith(
          id: uid,
          email: firestoreEmail ?? authUser.email ?? currentUser.email,
          fullName: fullName.isEmpty ? null : fullName,
          phoneNumber: phone,
          insuranceNumber: insuranceNumber,
          isEmailVerified: authUser.emailVerified,
          mainInsuranceProfileId: insuranceProfile?.id,
          updatedAt: currentUser.updatedAt,
          role: role,
        ),
        insuranceProfiles: insuranceProfile == null
            ? const <InsuranceProfile>[]
            : <InsuranceProfile>[insuranceProfile],
      );
    } catch (_) {
      state = state.copyWith(
        currentUser: currentUser.copyWith(
          id: uid,
          email: authUser.email ?? currentUser.email,
          fullName: authUser.displayName ?? currentUser.fullName,
          phoneNumber: authUser.phoneNumber ?? currentUser.phoneNumber,
          isEmailVerified: authUser.emailVerified,
          updatedAt: currentUser.updatedAt,
        ),
      );
    }
  }

  Future<void> _loadConstatsFromFirestore(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('constats')
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final loadedConstats = snapshot.docs
          .map((doc) {
            try {
              return Constat.fromJson(doc.data());
            } catch (e) {
              debugPrint('Error parsing constat ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Constat>()
          .toList();

      if (loadedConstats.isEmpty) {
        return;
      }

      // Merge loaded constats into state
      final mergedConstats = <String, Constat>{};

      // Add existing in-memory constats first
      for (final constat in state.constats) {
        mergedConstats[constat.id] = constat;
      }

      // Add/overwrite with Firestore constats
      for (final constat in loadedConstats) {
        mergedConstats[constat.id] = constat;
      }

      final sortedConstats = mergedConstats.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Find active draft (most recent draft constat)
      final activeDraft = sortedConstats
          .where((c) => c.status == ConstatStatus.draft)
          .firstOrNull;

      state = state.copyWith(
        constats: List<Constat>.unmodifiable(sortedConstats),
        activeConstat: activeDraft,
      );

      debugPrint('Loaded ${loadedConstats.length} constats from Firestore');

      // Backfill: create any notifications that were missed for pending
      // approval constats (e.g. written before the rules fix was deployed).
      await _ensureNotificationsForPendingConstats();
    } catch (e) {
      debugPrint('Error loading constats from Firestore: $e');
      // Don't crash - keep local state
    }
  }

  Future<void> _saveConstatToFirestore(Constat constat) async {
    try {
      final userId = constat.userId;
      if (userId.isEmpty) {
        debugPrint('Cannot save constat: userId is empty');
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('constats')
          .doc(constat.id)
          .set(constat.toJson(), SetOptions(merge: true));

      debugPrint('Saved constat ${constat.id} to Firestore');
    } catch (e) {
      debugPrint('Error saving constat to Firestore: $e');
      // Don't crash - local state is already updated
    }
  }

  Future<void> _loadScansFromFirestore(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('scans')
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final loadedScans = snapshot.docs
          .map((doc) {
            try {
              return DocumentScan.fromJson(doc.data());
            } catch (e) {
              debugPrint('Error parsing scan ${doc.id}: $e');
              return null;
            }
          })
          .whereType<DocumentScan>()
          .toList();

      if (loadedScans.isEmpty) {
        return;
      }

      // Merge loaded scans into state
      final mergedScans = <String, DocumentScan>{};

      // Add existing in-memory scans first
      for (final scan in state.scans) {
        mergedScans[scan.id] = scan;
      }

      // Add/overwrite with Firestore scans
      for (final scan in loadedScans) {
        mergedScans[scan.id] = scan;
      }

      final sortedScans = mergedScans.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = state.copyWith(
        scans: List<DocumentScan>.unmodifiable(sortedScans),
      );

      debugPrint('Loaded ${loadedScans.length} scans from Firestore');
    } catch (e) {
      debugPrint('Error loading scans from Firestore: $e');
      // Don't crash - keep local state
    }
  }

  Future<void> _saveScanToFirestore(DocumentScan scan) async {
    try {
      final userId = scan.userId;
      if (userId.isEmpty) {
        debugPrint('Cannot save scan: userId is empty');
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('scans')
          .doc(scan.id)
          .set(scan.toJson(), SetOptions(merge: true));

      debugPrint('Saved scan ${scan.id} to Firestore');
    } catch (e) {
      debugPrint('Error saving scan to Firestore: $e');
      // Don't crash - local state is already updated
    }
  }

  Future<String?> _uploadPhotoToStorage({
    required String userId,
    required String scanId,
    required String localFilePath,
  }) async {
    try {
      final file = File(localFilePath);
      if (!await file.exists()) {
        debugPrint('Photo file does not exist: $localFilePath');
        return null;
      }

      // Storage path: users/{userId}/scans/{scanId}/photo.jpg
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(userId)
          .child('scans')
          .child(scanId)
          .child('photo.jpg');

      debugPrint('Uploading photo to Storage: ${storageRef.fullPath}');

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Photo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading photo to Storage: $e');
      return null;
    }
  }

  String? _stringOrNull(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void syncCurrentUserProfile({
    required String firstName,
    required String lastName,
    required String phone,
  }) {
    final fullName = [
      firstName.trim(),
      lastName.trim(),
    ].where((value) => value.isNotEmpty).join(' ');

    state = state.copyWith(
      currentUser: state.currentUser.copyWith(
        fullName: fullName.isEmpty ? state.currentUser.fullName : fullName,
        phoneNumber: phone.trim().isEmpty
            ? state.currentUser.phoneNumber
            : phone.trim(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  DocumentScan startVehicleScan() {
    final now = DateTime.now();
    final scan = DocumentScan(
      id: _id('scan'),
      userId: state.currentUser.id,
      scanType: DocumentScanType.vehiclePhoto,
      status: DocumentScanStatus.pending,
      source: 'camera',
      notes: 'Vehicle capture started from the scan center.',
      createdAt: now,
      updatedAt: now,
    );

    state = state.copyWith(activeScan: scan, scans: _upsertScan(scan));

    return scan;
  }

  DocumentScan startCarteGriseScan({String source = 'camera'}) {
    final now = DateTime.now();
    final scan = DocumentScan(
      id: _id('scan'),
      userId: state.currentUser.id,
      scanType: DocumentScanType.carteGrise,
      status: DocumentScanStatus.pending,
      source: source,
      notes: 'Carte grise capture started from the document scan flow.',
      createdAt: now,
      updatedAt: now,
    );

    state = state.copyWith(activeScan: scan, scans: _upsertScan(scan));

    return scan;
  }

  void markActiveScanProcessing() {
    final activeScan = state.activeScan;
    if (activeScan == null) return;

    final updatedScan = activeScan.copyWith(
      status: DocumentScanStatus.processing,
      notes: 'OCR and validation are running on the captured document.',
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(
      activeScan: updatedScan,
      scans: _upsertScan(updatedScan),
    );
  }

  void completeActiveScan() {
    final activeScan = state.activeScan;
    if (activeScan == null) return;

    final now = DateTime.now();
    final extractedData = <String, dynamic>{
      'plateNumber': '123 TUN 456',
      'brand': 'Peugeot',
      'model': '208',
      'vin': 'VF3XXXXXXXXXXXX',
      'ownerName': 'Mohamed Ben Ali',
      'insuranceCompany': 'STAR Assurances',
      'insuranceNumber': 'INS-2026-0001',
      'policyType': 'Auto',
      'driverFullName': state.currentUser.fullName ?? 'Mohamed Ben Ali',
      'driverLicenseNumber': 'DL-123456',
      'driverPhoneNumber': state.currentUser.phoneNumber,
      'qualityLabel': 'Vehicle detected',
      'qualityScore': 0.82,
      'summary':
          'Plate text recognized successfully. Vehicle details were extracted into reusable profiles.',
    };

    final insuranceProfile = _buildInsuranceProfile(
      scanId: activeScan.id,
      extractedData: extractedData,
      now: now,
    );
    final vehicleProfile = _buildVehicleProfile(
      scanId: activeScan.id,
      insuranceProfileId: insuranceProfile.id,
      extractedData: extractedData,
      now: now,
    );
    final driverProfile = _buildDriverProfile(
      scanId: activeScan.id,
      extractedData: extractedData,
      now: now,
    );

    final completedScan = activeScan.copyWith(
      status: DocumentScanStatus.completed,
      ocrRawText: extractedData['plateNumber'] as String?,
      extractedData: extractedData,
      confidenceScore: 0.89,
      qualityScore: extractedData['qualityScore'] as double,
      relatedProfileId: vehicleProfile.id,
      relatedProfileType: ProfileType.vehicle,
      notes: extractedData['summary'] as String?,
      processedAt: now,
      updatedAt: now,
    );

    state = state.copyWith(
      currentUser: state.currentUser.copyWith(
        mainInsuranceProfileId: insuranceProfile.id,
        mainVehicleProfileId: vehicleProfile.id,
        mainDriverProfileId: driverProfile.id,
        updatedAt: now,
      ),
      activeScan: completedScan,
      insuranceProfiles: _upsertInsuranceProfile(insuranceProfile),
      vehicleProfiles: _upsertVehicleProfile(vehicleProfile),
      driverProfiles: _upsertDriverProfile(driverProfile),
      scans: _upsertScan(completedScan),
    );
  }

  void completeCarteGriseScan({
    required String plateNumber,
    required String ownerName,
    required String brand,
    required String model,
    required String vin,
    double confidence = 0.0,
    String? registrationDate,
    String? debugRawText,
    String? debugCleanedText,
  }) {
    final activeScan = state.activeScan;
    if (activeScan == null) return;

    final now = DateTime.now();
    final confidenceLevel = confidence >= 0.70
        ? 'good'
        : confidence >= 0.40
        ? 'medium'
        : 'weak';
    final qualityLabel = confidence >= 0.70
        ? 'Document recognized'
        : confidence >= 0.40
        ? 'Partial recognition'
        : 'Low confidence';
    final extractedData = <String, dynamic>{
      'plateNumber': plateNumber,
      'ownerName': ownerName,
      'brand': brand,
      'model': model,
      'vin': vin,
      'registrationDate': registrationDate,
      'qualityLabel': qualityLabel,
      'qualityScore': confidence,
      'confidenceLevel': confidenceLevel,
      'summary':
          'Carte grise data was extracted and attached to the vehicle profile flow.',
      if (kDebugMode && debugRawText != null) '_debug_raw_ocr': debugRawText,
      if (kDebugMode && debugCleanedText != null) '_debug_cleaned_ocr': debugCleanedText,
    };

    final existingVehicle = state.mainVehicleProfile;
    final vehicleProfile =
        (existingVehicle ??
                VehicleProfile(
                  id: _id('vehicle'),
                  userId: state.currentUser.id,
                  plateNumber: plateNumber,
                  isPrimary: true,
                  verificationStatus: ProfileVerificationStatus.extracted,
                  createdAt: now,
                  updatedAt: now,
                ))
            .copyWith(
              plateNumber: plateNumber,
              brand: brand,
              model: model,
              vin: vin,
              registrationDocumentScanId: activeScan.id,
              isPrimary: true,
              verificationStatus: ProfileVerificationStatus.extracted,
              updatedAt: now,
            );

    final completedScan = activeScan.copyWith(
      status: DocumentScanStatus.completed,
      ocrRawText: plateNumber,
      extractedData: extractedData,
      confidenceScore: confidence,
      qualityScore: confidence,
      relatedProfileId: vehicleProfile.id,
      relatedProfileType: ProfileType.vehicle,
      notes: extractedData['summary'] as String?,
      processedAt: now,
      updatedAt: now,
    );

    state = state.copyWith(
      currentUser: state.currentUser.copyWith(
        mainVehicleProfileId: vehicleProfile.id,
        updatedAt: now,
      ),
      activeScan: completedScan,
      vehicleProfiles: _upsertVehicleProfile(vehicleProfile),
      scans: _upsertScan(completedScan),
    );
  }

  // ---------------------------------------------------------------------------
  // Permis (driver license) scan completion
  // ---------------------------------------------------------------------------

  DocumentScan startPermisScan({String source = 'camera'}) {
    final now = DateTime.now();
    final scan = DocumentScan(
      id: _id('scan'),
      userId: state.currentUser.id,
      scanType: DocumentScanType.driverLicense,
      status: DocumentScanStatus.pending,
      source: source,
      notes: 'Permis capture started from the document scan flow.',
      createdAt: now,
      updatedAt: now,
    );
    state = state.copyWith(activeScan: scan, scans: _upsertScan(scan));
    return scan;
  }

  void completePermisScan({
    required String fullName,
    required String licenseNumber,
    required String nationalId,
    required String dateOfBirth,
    required String category,
    double confidence = 0.0,
    String? debugRawText,
    String? debugCleanedText,
  }) {
    final activeScan = state.activeScan;
    if (activeScan == null) return;

    final now = DateTime.now();
    final confidenceLevel = confidence >= 0.70
        ? 'good'
        : confidence >= 0.40
        ? 'medium'
        : 'weak';
    final qualityLabel = confidence >= 0.70
        ? 'License recognized'
        : confidence >= 0.40
        ? 'Partial recognition'
        : 'Low confidence';
    final extractedData = <String, dynamic>{
      'fullName': fullName,
      'licenseNumber': licenseNumber,
      'nationalId': nationalId,
      'dateOfBirth': dateOfBirth,
      'category': category,
      'qualityLabel': qualityLabel,
      'qualityScore': confidence,
      'confidenceLevel': confidenceLevel,
      'summary': 'Driver license data extracted from permis scan.',
      if (kDebugMode && debugRawText != null) '_debug_raw_ocr': debugRawText,
      if (kDebugMode && debugCleanedText != null) '_debug_cleaned_ocr': debugCleanedText,
    };

    final existing = state.mainDriverProfile;
    final driverProfile =
        (existing ??
                DriverProfile(
                  id: _id('driver'),
                  userId: state.currentUser.id,
                  fullName: fullName,
                  isPrimary: true,
                  verificationStatus: ProfileVerificationStatus.extracted,
                  createdAt: now,
                  updatedAt: now,
                ))
            .copyWith(
              fullName: fullName.isEmpty ? existing?.fullName : fullName,
              licenseNumber: licenseNumber.isEmpty ? null : licenseNumber,
              nationalId: nationalId.isEmpty ? null : nationalId,
              // Parse raw OCR date string → DateTime? (null kept if parsing fails)
              dateOfBirth: OcrDateParser.tryParse(dateOfBirth) ?? existing?.dateOfBirth,
              licenseCategory: category.isEmpty ? null : category,
              driverDocumentScanId: activeScan.id,
              isPrimary: true,
              verificationStatus: ProfileVerificationStatus.extracted,
              updatedAt: now,
            );

    final completedScan = activeScan.copyWith(
      status: DocumentScanStatus.completed,
      ocrRawText: licenseNumber,
      extractedData: extractedData,
      confidenceScore: confidence,
      qualityScore: confidence,
      relatedProfileId: driverProfile.id,
      relatedProfileType: ProfileType.driver,
      notes: extractedData['summary'] as String?,
      processedAt: now,
      updatedAt: now,
    );

    state = state.copyWith(
      currentUser: state.currentUser.copyWith(
        mainDriverProfileId: driverProfile.id,
        updatedAt: now,
      ),
      activeScan: completedScan,
      driverProfiles: _upsertDriverProfile(driverProfile),
      scans: _upsertScan(completedScan),
    );
  }

  // ---------------------------------------------------------------------------
  // Assurance (insurance) scan completion
  // ---------------------------------------------------------------------------

  DocumentScan startAssuranceScan({String source = 'camera'}) {
    final now = DateTime.now();
    final scan = DocumentScan(
      id: _id('scan'),
      userId: state.currentUser.id,
      scanType: DocumentScanType.insurance,
      status: DocumentScanStatus.pending,
      source: source,
      notes: 'Assurance capture started from the document scan flow.',
      createdAt: now,
      updatedAt: now,
    );
    state = state.copyWith(activeScan: scan, scans: _upsertScan(scan));
    return scan;
  }

  void completeAssuranceScan({
    required String insuranceNumber,
    required String companyName,
    required String policyHolderName,
    required String policyType,
    required String validFrom,
    required String validTo,
    double confidence = 0.0,
    String? debugRawText,
    String? debugCleanedText,
  }) {
    final activeScan = state.activeScan;
    if (activeScan == null) return;

    final now = DateTime.now();
    final confidenceLevel = confidence >= 0.70
        ? 'good'
        : confidence >= 0.40
        ? 'medium'
        : 'weak';
    final qualityLabel = confidence >= 0.70
        ? 'Insurance document recognized'
        : confidence >= 0.40
        ? 'Partial recognition'
        : 'Low confidence';
    final extractedData = <String, dynamic>{
      'insuranceNumber': insuranceNumber,
      'companyName': companyName,
      'policyHolderName': policyHolderName,
      'policyType': policyType,
      'validFrom': validFrom,
      'validTo': validTo,
      'qualityLabel': qualityLabel,
      'qualityScore': confidence,
      'confidenceLevel': confidenceLevel,
      'summary': 'Insurance attestation data extracted from assurance scan.',
      if (kDebugMode && debugRawText != null) '_debug_raw_ocr': debugRawText,
      if (kDebugMode && debugCleanedText != null) '_debug_cleaned_ocr': debugCleanedText,
    };

    final existing = state.mainInsuranceProfile;
    final insuranceProfile =
        (existing ??
                InsuranceProfile(
                  id: _id('insurance'),
                  userId: state.currentUser.id,
                  insuranceNumber: insuranceNumber,
                  companyName: companyName,
                  isPrimary: true,
                  verificationStatus: ProfileVerificationStatus.extracted,
                  createdAt: now,
                  updatedAt: now,
                ))
            .copyWith(
              insuranceNumber: insuranceNumber.isEmpty
                  ? existing?.insuranceNumber ?? ''
                  : insuranceNumber,
              companyName: companyName.isEmpty
                  ? existing?.companyName ?? ''
                  : companyName,
              policyHolderName: policyHolderName.isEmpty
                  ? null
                  : policyHolderName,
              policyType: policyType.isEmpty ? null : policyType,
              documentScanId: activeScan.id,
              isPrimary: true,
              verificationStatus: ProfileVerificationStatus.extracted,
              updatedAt: now,
            );

    final completedScan = activeScan.copyWith(
      status: DocumentScanStatus.completed,
      ocrRawText: insuranceNumber,
      extractedData: extractedData,
      confidenceScore: confidence,
      qualityScore: confidence,
      relatedProfileId: insuranceProfile.id,
      relatedProfileType: ProfileType.insurance,
      notes: extractedData['summary'] as String?,
      processedAt: now,
      updatedAt: now,
    );

    state = state.copyWith(
      currentUser: state.currentUser.copyWith(
        mainInsuranceProfileId: insuranceProfile.id,
        updatedAt: now,
      ),
      activeScan: completedScan,
      insuranceProfiles: _upsertInsuranceProfile(insuranceProfile),
      scans: _upsertScan(completedScan),
    );
  }

  void updateCarteGriseDraft({
    required String plateNumber,
    required String ownerName,
    required String brand,
    required String model,
    required String vin,
  }) {
    final activeScan = state.activeScan;
    final now = DateTime.now();
    final extractedData = <String, dynamic>{
      ...?activeScan?.extractedData,
      'plateNumber': plateNumber,
      'ownerName': ownerName,
      'brand': brand,
      'model': model,
      'vin': vin,
      'qualityLabel':
          activeScan?.extractedData?['qualityLabel'] as String? ??
          'Document recognized',
      'qualityScore':
          activeScan?.extractedData?['qualityScore'] as double? ?? 0.91,
      'summary':
          activeScan?.extractedData?['summary'] as String? ??
          'Carte grise data was extracted and attached to the vehicle profile flow.',
    };

    if (activeScan != null) {
      final updatedScan = activeScan.copyWith(
        ocrRawText: plateNumber,
        extractedData: extractedData,
        updatedAt: now,
      );

      state = state.copyWith(
        activeScan: updatedScan,
        scans: _upsertScan(updatedScan),
      );
    }

    final existingVehicle = state.mainVehicleProfile;
    if (existingVehicle != null) {
      final updatedVehicle = existingVehicle.copyWith(
        plateNumber: plateNumber,
        brand: brand,
        model: model,
        vin: vin,
        registrationDocumentScanId:
            activeScan?.id ?? existingVehicle.registrationDocumentScanId,
        verificationStatus: ProfileVerificationStatus.extracted,
        updatedAt: now,
      );

      state = state.copyWith(
        vehicleProfiles: _upsertVehicleProfile(updatedVehicle),
      );
    }
  }

  void startDraftConstat() {
    final now = DateTime.now();
    final current = state.activeConstat;

    if (current != null && current.status == ConstatStatus.draft) {
      return;
    }

    final draft = Constat(
      id: _id('constat'),
      userId: state.currentUser.id,
      referenceNumber: _constatReference(now),
      status: ConstatStatus.draft,
      driverProfileId: state.mainDriverProfile?.id,
      vehicleProfileId: state.mainVehicleProfile?.id,
      insuranceProfileId: state.mainInsuranceProfile?.id,
      driverSnapshot: state.mainDriverProfile?.toJson(),
      vehicleSnapshot: state.mainVehicleProfile?.toJson(),
      insuranceSnapshot: state.mainInsuranceProfile?.toJson(),
      photoScanIds: state.activeScan == null
          ? const <String>[]
          : <String>[state.activeScan!.id],
      supportingDocumentScanIds: state.activeScan == null
          ? const <String>[]
          : <String>[state.activeScan!.id],
      isAutoFilled:
          state.mainDriverProfile != null ||
          state.mainVehicleProfile != null ||
          state.mainInsuranceProfile != null,
      createdAt: now,
      updatedAt: now,
    );

    state = state.copyWith(
      activeConstat: draft,
      constats: _upsertConstat(draft),
    );

    // Save to Firestore asynchronously
    _saveConstatToFirestore(draft);
  }

  void saveAccidentDetails({
    required DateTime? dateTime,
    required String location,
    required String description,
    required String notes,
    required List<Map<String, dynamic>>? extractedEntities,
  }) {
    final draft = state.activeConstat;
    if (draft == null) return;

    final updated = draft.copyWith(
      accidentDateTime: dateTime,
      accidentLocation: location.isEmpty ? null : location,
      accidentDescription: description.isEmpty ? null : description,
      notes: notes.isEmpty ? null : notes,
      extractedEntities: extractedEntities,
      updatedAt: DateTime.now(),
    );

    _setActiveConstat(updated);
  }

  void updateAccidentStep() {
    final draft = state.activeConstat;
    if (draft == null) return;

    final updated = draft.copyWith(
      accidentDateTime: DateTime.now().subtract(const Duration(minutes: 45)),
      accidentLocation: 'Tunis - City Center',
      accidentDescription:
          'Low-speed urban collision recorded as a draft from the guided flow.',
      notes:
          'Weather was clear and traffic was moderate at the time of the incident.',
      updatedAt: DateTime.now(),
    );

    _setActiveConstat(updated);
  }

  void updateDriverStep() {
    final draft = state.activeConstat;
    if (draft == null) return;

    final updated = draft.copyWith(
      driverProfileId: state.mainDriverProfile?.id,
      driverSnapshot: state.mainDriverProfile?.toJson(),
      isAutoFilled: state.mainDriverProfile != null || draft.isAutoFilled,
      updatedAt: DateTime.now(),
    );

    _setActiveConstat(updated);
  }

  void saveConstatDriverDraft({
    required String fullName,
    required String licenseNumber,
    required String nationalId,
    required String phoneNumber,
  }) {
    final now = DateTime.now();
    final existing = state.mainDriverProfile;
    final driverProfile =
        (existing ??
                DriverProfile(
                  id: _id('driver'),
                  userId: state.currentUser.id,
                  fullName: fullName,
                  isPrimary: true,
                  verificationStatus: ProfileVerificationStatus.confirmed,
                  createdAt: now,
                  updatedAt: now,
                ))
            .copyWith(
              fullName: fullName,
              licenseNumber: licenseNumber.isEmpty ? null : licenseNumber,
              nationalId: nationalId.isEmpty ? null : nationalId,
              phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
              isPrimary: true,
              verificationStatus: ProfileVerificationStatus.confirmed,
              updatedAt: now,
            );

    final nextState = state.copyWith(
      currentUser: state.currentUser.copyWith(
        mainDriverProfileId: driverProfile.id,
        updatedAt: now,
      ),
      driverProfiles: _upsertDriverProfile(driverProfile),
    );

    state = nextState;
    updateDriverStep();
  }

  void updateVehicleStep() {
    final draft = state.activeConstat;
    if (draft == null) return;

    final updated = draft.copyWith(
      vehicleProfileId: state.mainVehicleProfile?.id,
      insuranceProfileId: state.mainInsuranceProfile?.id,
      vehicleSnapshot: state.mainVehicleProfile?.toJson(),
      insuranceSnapshot: state.mainInsuranceProfile?.toJson(),
      isAutoFilled:
          state.mainVehicleProfile != null ||
          state.mainInsuranceProfile != null ||
          draft.isAutoFilled,
      updatedAt: DateTime.now(),
    );

    _setActiveConstat(updated);
  }

  void saveConstatVehicleDraft({
    required String plateNumber,
    required String brand,
    required String model,
    required String vin,
  }) {
    final now = DateTime.now();
    final existing = state.mainVehicleProfile;
    final vehicleProfile =
        (existing ??
                VehicleProfile(
                  id: _id('vehicle'),
                  userId: state.currentUser.id,
                  plateNumber: plateNumber,
                  isPrimary: true,
                  verificationStatus: ProfileVerificationStatus.confirmed,
                  createdAt: now,
                  updatedAt: now,
                ))
            .copyWith(
              plateNumber: plateNumber,
              brand: brand.isEmpty ? null : brand,
              model: model.isEmpty ? null : model,
              vin: vin.isEmpty ? null : vin,
              isPrimary: true,
              verificationStatus: ProfileVerificationStatus.confirmed,
              updatedAt: now,
            );

    final nextState = state.copyWith(
      currentUser: state.currentUser.copyWith(
        mainVehicleProfileId: vehicleProfile.id,
        updatedAt: now,
      ),
      vehicleProfiles: _upsertVehicleProfile(vehicleProfile),
    );

    state = nextState;
    updateVehicleStep();
  }

  void saveConstatInsuranceDraft({
    required String insuranceNumber,
    required String companyName,
    required String policyHolderName,
    required String policyType,
    String partyBInsuranceNumber = '',
    String partyBCompanyName = '',
    String partyBPolicyHolderName = '',
    String partyBPolicyType = '',
  }) {
    final now = DateTime.now();
    final existing = state.mainInsuranceProfile;
    final insuranceProfile =
        (existing ??
                InsuranceProfile(
                  id: _id('insurance'),
                  userId: state.currentUser.id,
                  insuranceNumber: insuranceNumber,
                  companyName: companyName,
                  isPrimary: true,
                  verificationStatus: ProfileVerificationStatus.confirmed,
                  createdAt: now,
                  updatedAt: now,
                ))
            .copyWith(
              insuranceNumber: insuranceNumber,
              companyName: companyName,
              policyHolderName: policyHolderName.isEmpty
                  ? null
                  : policyHolderName,
              policyType: policyType.isEmpty ? null : policyType,
              isPrimary: true,
              verificationStatus: ProfileVerificationStatus.confirmed,
              updatedAt: now,
            );

    final nextState = state.copyWith(
      currentUser: state.currentUser.copyWith(
        mainInsuranceProfileId: insuranceProfile.id,
        updatedAt: now,
      ),
      insuranceProfiles: _upsertInsuranceProfile(insuranceProfile),
    );

    state = nextState;
    updateVehicleStep(); // sets insuranceSnapshot from mainInsuranceProfile

    // Patch active constat with separate Party A / Party B snapshots
    final draft = state.activeConstat;
    if (draft != null) {
      final partyASnap = <String, dynamic>{
        'insuranceNumber': insuranceNumber,
        'companyName': companyName,
        'policyHolderName': policyHolderName.isEmpty ? null : policyHolderName,
        'policyType': policyType.isEmpty ? null : policyType,
      };

      final trimmedPartyB = partyBInsuranceNumber.trim();
      final partyBSnap = trimmedPartyB.isEmpty
          ? null
          : <String, dynamic>{
              'insuranceNumber': trimmedPartyB,
              'companyName': partyBCompanyName.isEmpty
                  ? null
                  : partyBCompanyName,
              'policyHolderName': partyBPolicyHolderName.isEmpty
                  ? null
                  : partyBPolicyHolderName,
              'policyType': partyBPolicyType.isEmpty ? null : partyBPolicyType,
            };

      final updated = draft.copyWith(
        partyAInsuranceSnapshot: partyASnap,
        partyBTargetInsuranceSnapshot: partyBSnap,
        updatedAt: DateTime.now(),
      );
      _setActiveConstat(updated);
    }
  }

  void updateDamageStep() {
    final draft = state.activeConstat;
    if (draft == null) return;

    final photoIds = <String>[
      ...draft.photoScanIds,
      if (state.activeScan != null &&
          !draft.photoScanIds.contains(state.activeScan!.id))
        state.activeScan!.id,
    ];

    final updated = draft.copyWith(
      photoScanIds: photoIds,
      supportingDocumentScanIds: _mergeUnique(
        draft.supportingDocumentScanIds,
        photoIds,
      ),
      notes: _composeDamageNote(draft.notes, ''),
      updatedAt: DateTime.now(),
    );

    _setActiveConstat(updated);
  }

  void recordDamagePhotoEvidence({
    required String label,
    required String source,
    required String localFilePath,
    required String? annotatedImageUrl,
    required bool damageDetected,
    required Map<String, dynamic> extractedData,
    required String scanNote,
    required String evidenceNote,
    double? confidenceScore,
  }) {
    final now = DateTime.now();
    final scan = DocumentScan(
      id: _id('damage_photo'),
      userId: state.currentUser.id,
      scanType: DocumentScanType.vehiclePhoto,
      status: DocumentScanStatus.completed,
      source: source,
      fileUrl: annotatedImageUrl,
      localFilePath: localFilePath,
      thumbnailUrl: annotatedImageUrl,
      extractedData: <String, dynamic>{
        'label': label,
        'damageDetected': damageDetected,
        ...extractedData,
      },
      confidenceScore: confidenceScore,
      qualityScore: confidenceScore,
      notes: scanNote,
      processedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    final draft = state.activeConstat;
    state = state.copyWith(activeScan: scan, scans: _upsertScan(scan));

    // Upload photo to Firebase Storage and save scan to Firestore
    _uploadAndPersistScan(scan, localFilePath);

    if (draft == null) return;

    final photoIds = _mergeUnique(draft.photoScanIds, <String>[scan.id]);
    final supportingIds = _mergeUnique(
      draft.supportingDocumentScanIds,
      <String>[scan.id],
    );

    final updated = draft.copyWith(
      photoScanIds: photoIds,
      supportingDocumentScanIds: supportingIds,
      notes: _composeDamageNote(draft.notes, evidenceNote),
      updatedAt: now,
    );

    _setActiveConstat(updated);
  }

  Future<void> _uploadAndPersistScan(
    DocumentScan scan,
    String localFilePath,
  ) async {
    try {
      // Upload photo to Firebase Storage
      final downloadUrl = await _uploadPhotoToStorage(
        userId: scan.userId,
        scanId: scan.id,
        localFilePath: localFilePath,
      );

      // Update scan with download URL if upload succeeded
      if (downloadUrl != null) {
        final updatedScan = scan.copyWith(
          fileUrl: downloadUrl,
          thumbnailUrl: downloadUrl,
          updatedAt: DateTime.now(),
        );

        // Update local state
        state = state.copyWith(
          scans: _upsertScan(updatedScan),
          activeScan: state.activeScan?.id == scan.id
              ? updatedScan
              : state.activeScan,
        );

        // Save updated scan to Firestore
        await _saveScanToFirestore(updatedScan);
      } else {
        // Upload failed, save scan with local path only
        await _saveScanToFirestore(scan);
      }
    } catch (e) {
      debugPrint('Error in _uploadAndPersistScan: $e');
      // Still try to save scan metadata even if upload failed
      await _saveScanToFirestore(scan);
    }
  }

  /// Update user profile insurance number with Firestore lookup management
  /// Returns true if update succeeded, false if insurance number is already taken
  Future<bool> updateProfileInsuranceNumber(String newInsuranceNumber) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      debugPrint('Cannot update insurance number: no authenticated user');
      return false;
    }

    final uid = authUser.uid;
    final trimmedNumber = newInsuranceNumber.trim();

    if (trimmedNumber.isEmpty) {
      debugPrint('Cannot update insurance number: empty value');
      return false;
    }

    try {
      final currentUser = state.currentUser;
      final oldInsuranceNumber = currentUser.insuranceNumber;

      // Check if new insurance number is already registered to another user
      final insuranceLookupDoc = await FirebaseFirestore.instance
          .collection('insurance_users')
          .doc(trimmedNumber)
          .get();

      if (insuranceLookupDoc.exists) {
        final existingUid = insuranceLookupDoc.data()?['uid'] as String?;
        if (existingUid != null && existingUid != uid) {
          debugPrint(
            'Insurance number $trimmedNumber is already registered to another user',
          );
          return false;
        }
      }

      // Update user profile document
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'insuranceNumber': trimmedNumber,
      }, SetOptions(merge: true));

      // Create/update new insurance_users lookup
      final fullName = currentUser.fullName ?? '';
      final email = currentUser.email;
      final phone = currentUser.phoneNumber ?? '';

      final Object createdAtValue;
      if (insuranceLookupDoc.exists) {
        createdAtValue =
            insuranceLookupDoc.data()?['createdAt'] ??
            FieldValue.serverTimestamp();
      } else {
        createdAtValue = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection('insurance_users')
          .doc(trimmedNumber)
          .set({
            'uid': uid,
            'fullName': fullName,
            'email': email,
            'phone': phone,
            'createdAt': createdAtValue,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Delete old insurance_users lookup if it belongs to current user
      if (oldInsuranceNumber != null &&
          oldInsuranceNumber.isNotEmpty &&
          oldInsuranceNumber != trimmedNumber) {
        final oldLookupDoc = await FirebaseFirestore.instance
            .collection('insurance_users')
            .doc(oldInsuranceNumber)
            .get();

        if (oldLookupDoc.exists) {
          final oldUid = oldLookupDoc.data()?['uid'] as String?;
          if (oldUid == uid) {
            await FirebaseFirestore.instance
                .collection('insurance_users')
                .doc(oldInsuranceNumber)
                .delete();
            debugPrint('Deleted old insurance lookup: $oldInsuranceNumber');
          }
        }
      }

      // Update local state
      state = state.copyWith(
        currentUser: currentUser.copyWith(
          insuranceNumber: trimmedNumber,
          updatedAt: DateTime.now(),
        ),
      );

      debugPrint('Successfully updated insurance number to: $trimmedNumber');
      return true;
    } catch (e) {
      debugPrint('Error updating insurance number: $e');
      return false;
    }
  }

  void saveDamageDraft({required String evidenceNote}) {
    final draft = state.activeConstat;
    if (draft == null) return;

    final photoIds = <String>[
      ...draft.photoScanIds,
      if (state.activeScan != null &&
          !draft.photoScanIds.contains(state.activeScan!.id))
        state.activeScan!.id,
    ];

    final updated = draft.copyWith(
      photoScanIds: photoIds,
      supportingDocumentScanIds: _mergeUnique(
        draft.supportingDocumentScanIds,
        photoIds,
      ),
      notes: _composeDamageNote(draft.notes, evidenceNote),
      updatedAt: DateTime.now(),
    );

    _setActiveConstat(updated);
  }

  void saveSignatureDraft({
    required String signerName,
    required bool confirmed,
  }) {
    final draft = state.activeConstat;
    if (draft == null) return;

    final confirmationNote = confirmed
        ? 'Confirmed by ${signerName.isEmpty ? state.currentUser.fullName ?? 'current user' : signerName}.'
        : 'Confirmation pending.';

    final updated = draft.copyWith(
      notes:
          '${draft.notes ?? 'Draft prepared for submission.'} $confirmationNote',
      updatedAt: DateTime.now(),
    );

    _setActiveConstat(updated);
  }

  void submitConstat() {
    final draft = state.activeConstat;
    if (draft == null) return;

    // Validate Party A insurance number is present
    final insuranceNumber =
        _stringOrNull(draft.partyAInsuranceSnapshot?['insuranceNumber']) ??
        _stringOrNull(draft.insuranceSnapshot?['insuranceNumber']);
    if (insuranceNumber == null) {
      debugPrint('Cannot submit constat: Party A insurance number is required');
      return;
    }

    final now = DateTime.now();
    final submitted = draft.copyWith(
      status: ConstatStatus.submitted,
      submittedAt: now,
      updatedAt: now,
    );

    state = state.copyWith(
      activeConstat: submitted,
      constats: _upsertConstat(submitted),
    );

    // Save to Firestore asynchronously
    _saveConstatToFirestore(submitted);

    // Create approval request if possible
    createApprovalRequestIfPossible(submitted);
  }

  /// Create approval request for the other party identified by insurance number.
  Future<void> createApprovalRequestIfPossible(Constat constat) async {
    debugPrint(
      '[Approval] createApprovalRequestIfPossible START — constat: ${constat.id}',
    );

    // Use partyBTargetInsuranceSnapshot (correct path); fall back to
    // insuranceSnapshot only for old constats that pre-date this field.
    final insuranceNumber =
        _stringOrNull(
          constat.partyBTargetInsuranceSnapshot?['insuranceNumber'],
        ) ??
        _stringOrNull(constat.insuranceSnapshot?['insuranceNumber']);

    debugPrint('[Approval] Target insurance number: $insuranceNumber');

    if (insuranceNumber == null) {
      debugPrint('[Approval] No Party B insurance number found — skipping');
      return;
    }

    final currentUserId = state.currentUser.id;

    if (state.currentUser.insuranceNumber == insuranceNumber) {
      debugPrint(
        '[Approval] Insurance number belongs to current user — skipping',
      );
      return;
    }

    // Phase 1: Resolve target user uid.
    // Fast path  → insurance_users/{insuranceNumber} (set up via profile settings).
    // Fallback   → query users collection directly on the insuranceNumber field
    //              for users who have the number saved but never ran the profile
    //              registration flow that populates insurance_users.
    // If neither path resolves a uid, the approval fields are still written to
    // Firestore (so the insurance number is persisted) but no notification is
    // created and approvalRequestedToUid remains null.
    String? targetUid;
    try {
      debugPrint('[Approval] Looking up insurance_users/$insuranceNumber ...');
      final lookupDoc = await FirebaseFirestore.instance
          .collection('insurance_users')
          .doc(insuranceNumber)
          .get();

      if (lookupDoc.exists) {
        final uid = lookupDoc.data()?['uid'] as String?;
        if (uid != null && uid.isNotEmpty) {
          if (uid == currentUserId) {
            debugPrint('[Approval] Target uid is current user — skipping');
            return;
          }
          targetUid = uid;
          debugPrint(
            '[Approval] Target uid resolved via insurance_users: $targetUid',
          );
        }
      }

      if (targetUid == null) {
        // Fallback: scan the users collection for a document whose
        // insuranceNumber field matches the Party B insurance number.
        debugPrint(
          '[Approval] insurance_users miss — scanning users collection '
          'for insuranceNumber=$insuranceNumber',
        );
        final usersQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('insuranceNumber', isEqualTo: insuranceNumber)
            .limit(1)
            .get();

        if (usersQuery.docs.isNotEmpty) {
          final uid = usersQuery.docs.first.id;
          if (uid == currentUserId) {
            debugPrint(
              '[Approval] users-collection match is current user — skipping',
            );
            return;
          }
          targetUid = uid;
          debugPrint(
            '[Approval] Target uid resolved via users collection: $targetUid',
          );
        } else {
          debugPrint(
            '[Approval] No matching user found for insurance number: '
            '$insuranceNumber — approvalRequestedToInsuranceNumber will be '
            'stored, approvalRequestedToUid will remain null',
          );
        }
      }
    } catch (e) {
      debugPrint('[Approval] Error resolving target uid: $e — continuing with null uid');
      // Continue with null targetUid: approval fields still get written below.
    }

    // Phase 2: Update constat with approval fields and persist.
    final now = DateTime.now();

    // Build a compact snapshot of photo scans so Party B can view damage photos
    // and cost estimation directly from the constat document — without needing
    // cross-user access to the owner's scans subcollection.
    final rawSnapshot = constat.photoScanIds
        .map((id) => state.scans.where((s) => s.id == id).firstOrNull)
        .whereType<DocumentScan>()
        .map(
          (scan) => <String, dynamic>{
            'id': scan.id,
            'userId': scan.userId,
            'scanType': scan.scanType.value,
            'status': scan.status.value,
            'source': scan.source,
            'fileUrl': scan.fileUrl,
            'thumbnailUrl': scan.thumbnailUrl,
            'extractedData': scan.extractedData,
            'createdAt': scan.createdAt.toIso8601String(),
            'updatedAt': scan.updatedAt.toIso8601String(),
          },
        )
        .toList();

    final updatedConstat = constat.copyWith(
      approvalStatus: 'pending',
      approvalRequestedToUid: targetUid,
      approvalRequestedToInsuranceNumber: insuranceNumber,
      approvalRequestedAt: now,
      updatedAt: now,
      photoScansSnapshot: rawSnapshot.isEmpty ? null : rawSnapshot,
    );

    state = state.copyWith(
      activeConstat: state.activeConstat?.id == updatedConstat.id
          ? updatedConstat
          : state.activeConstat,
      constats: _upsertConstat(updatedConstat),
    );

    try {
      await _saveConstatToFirestore(updatedConstat);
      debugPrint(
        '[Approval] Approval fields written to Firestore — constat ${constat.id} → user $targetUid',
      );
    } catch (e) {
      debugPrint('[Approval] Error saving approval fields: $e');
      // Local state already updated; Firestore will sync on next save.
    }

    // Phase 3: Notify target user — only when a uid was resolved.
    // Isolated so a Firestore rules failure here never rolls back the
    // approval-request write that already succeeded in Phase 2.
    if (targetUid != null) {
      await _createApprovalNotification(
        constatId: constat.id,
        targetUid: targetUid,
        ownerUid: constat.userId,
      );
    }
  }

  /// Write a constat-request notification to [targetUid]'s subcollection.
  ///
  /// Path: users/{targetUid}/notifications/notif_{constatId}
  ///
  /// [ownerUid] is Party A's uid, stored so Party B can navigate to
  /// users/{ownerUid}/constats/{constatId} from the notification tap.
  ///
  /// Uses a deterministic document ID (`notif_{constatId}`) so retries are
  /// idempotent. First write = Firestore `create` (needs `allow create: if
  /// request.auth != null`). Subsequent writes on an existing doc = Firestore
  /// `update` — typically denied, which is the expected backfill behavior
  /// (notification was already delivered).
  ///
  /// Errors are typed: FirebaseException.permission-denied is distinguished
  /// from other failures. createdAt is ISO-8601 for [dateTimeFromJson].
  Future<void> _createApprovalNotification({
    required String constatId,
    required String targetUid,
    required String ownerUid,
  }) async {
    if (targetUid.isEmpty || constatId.isEmpty) {
      debugPrint(
        '[Notif] Skipping — targetUid or constatId is empty '
        '(targetUid="$targetUid", constatId="$constatId")',
      );
      return;
    }

    // Deterministic ID — prevents duplicate notifications across retries
    // without needing a cross-user read (which Firestore rules block).
    final notificationId = 'notif_$constatId';

    debugPrint(
      '[Notif] Writing users/$targetUid/notifications/$notificationId '
      '(constatId=$constatId ownerUid=$ownerUid)',
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUid)
          .collection('notifications')
          .doc(notificationId)
          .set({
            'id': notificationId,
            'userId': targetUid,
            'type': 'constat_request',
            'title': 'New constat request',
            'body': 'A constat is waiting for your review.',
            'constatId': constatId,
            'ownerUid': ownerUid,
            'read': false,
            'createdAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));

      debugPrint(
        '[Notif] SUCCESS — $notificationId written for user $targetUid '
        '(constat=$constatId owner=$ownerUid)',
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // Permission denied means the Firestore rule blocked the write.
        // Required rule (must allow both create and update for cross-user):
        //   match /users/{userId}/notifications/{notifId} {
        //     allow create, update: if request.auth != null;
        //   }
        debugPrint(
          '[Notif] PERMISSION_DENIED — $notificationId for user $targetUid. '
          'Check Firestore rules: allow create, update must be set for '
          'users/{userId}/notifications/{notifId}.',
        );
      } else {
        debugPrint(
          '[Notif] FirebaseException [${e.code}] writing $notificationId '
          'for user $targetUid: ${e.message}',
        );
      }
    } catch (e) {
      debugPrint(
        '[Notif] Unexpected error writing $notificationId for user $targetUid: $e',
      );
    }
  }

  /// Backfill helper: ensures each locally-known constat with
  /// approvalStatus == "pending" has a notification in the target user's
  /// subcollection. Safe to call on every session load — the deterministic
  /// document ID inside [_createApprovalNotification] prevents double-writes.
  Future<void> _ensureNotificationsForPendingConstats() async {
    final pending = state.constats.where(
      (c) =>
          c.approvalStatus == 'pending' &&
          c.approvalRequestedToUid != null &&
          c.approvalRequestedToUid!.isNotEmpty,
    );
    for (final constat in pending) {
      await _createApprovalNotification(
        constatId: constat.id,
        targetUid: constat.approvalRequestedToUid!,
        ownerUid: constat.userId,
      );
    }
  }

  /// Fetch a constat owned by [ownerUid] and inject it into local state so
  /// that [getConstatById] can find it and existing save/respond methods work
  /// without modification.
  ///
  /// Safe to call repeatedly — skips the Firestore fetch if the constat is
  /// already in state.
  ///
  /// Requires Firestore rule on users/{ownerUid}/constats/{constatId}:
  ///   allow read: if request.auth.uid == resource.data.approvalRequestedToUid;
  Future<void> loadCrossUserConstatIntoState(
    String ownerUid,
    String constatId,
  ) async {
    if (state.constats.any((c) => c.id == constatId)) {
      debugPrint(
        '[CrossUser] Constat $constatId already in state — skipping fetch',
      );
      return;
    }

    debugPrint('[CrossUser] Fetching users/$ownerUid/constats/$constatId ...');

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerUid)
          .collection('constats')
          .doc(constatId)
          .get();

      if (!doc.exists) {
        debugPrint(
          '[CrossUser] Constat $constatId not found under owner $ownerUid',
        );
        return;
      }

      final constat = Constat.fromJson(doc.data()!);
      state = state.copyWith(constats: _upsertConstat(constat));
      debugPrint(
        '[CrossUser] Loaded constat $constatId (owner $ownerUid) into state',
      );
    } catch (e) {
      debugPrint('[CrossUser] Error loading constat $constatId: $e');
      rethrow;
    }
  }

  /// Respond to a constat approval request (accept or reject)
  Future<bool> respondToConstatApproval({
    required String constatId,
    required bool accepted,
  }) async {
    final currentUserId = state.currentUser.id;

    try {
      // Find the constat
      final constat = getConstatById(constatId);
      if (constat == null) {
        debugPrint('Constat not found: $constatId');
        return false;
      }

      // Verify current user is the requested approver
      if (constat.approvalRequestedToUid != currentUserId) {
        debugPrint('Current user is not the requested approver');
        return false;
      }

      // Verify status is pending
      if (constat.approvalStatus != 'pending') {
        debugPrint('Constat approval status is not pending');
        return false;
      }

      // If accepting, verify Party B info is complete
      if (accepted && !isPartyBInfoComplete(constat)) {
        debugPrint('Cannot accept: Party B information is not complete');
        return false;
      }

      final now = DateTime.now();
      final response = accepted ? 'accepted' : 'rejected';
      final newStatus = accepted ? 'accepted' : 'rejected';

      // Update constat
      final updatedConstat = constat.copyWith(
        approvalStatus: newStatus,
        approvalResponse: response,
        approvalRespondedAt: now,
        updatedAt: now,
      );

      // Update local state
      state = state.copyWith(constats: _upsertConstat(updatedConstat));

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(constat.userId)
          .collection('constats')
          .doc(constatId)
          .set(updatedConstat.toJson(), SetOptions(merge: true));

      if (accepted) {
        await _mirrorConstatToApproved(updatedConstat);
      } else {
        await _removeApprovedMirror(constatId);
      }

      // Notify Party A (the constat owner) of the response.
      // Isolated — a notification failure must never block the approval result.
      await _createResponseNotification(
        constatId: constatId,
        ownerUid: constat.userId,
        accepted: accepted,
      );

      debugPrint('Constat $constatId approval response: $response');
      return true;
    } catch (e) {
      debugPrint('Error responding to constat approval: $e');
      return false;
    }
  }

  /// Write an accept/reject response notification to Party A's notifications
  /// subcollection so they know User B has responded.
  ///
  /// Path: users/{ownerUid}/notifications/notif_response_{constatId}
  ///
  /// Uses a deterministic document ID so retries are idempotent (first write =
  /// Firestore `create`; subsequent attempts = `update`, denied — safe to
  /// ignore via the permission-denied catch below).
  ///
  /// Requires: match /users/{userId}/notifications/{notifId} {
  ///             allow create: if request.auth != null;  ← already in rules
  ///           }
  Future<void> _createResponseNotification({
    required String constatId,
    required String ownerUid,
    required bool accepted,
  }) async {
    if (ownerUid.isEmpty || constatId.isEmpty) {
      debugPrint(
        '[NotifResponse] Skipping — ownerUid or constatId is empty',
      );
      return;
    }

    final notificationId = 'notif_response_$constatId';
    final title = accepted ? 'Constat accepted' : 'Constat rejected';
    final body = accepted
        ? 'The other party has accepted your constat.'
        : 'The other party has rejected your constat.';

    debugPrint(
      '[NotifResponse] Writing users/$ownerUid/notifications/$notificationId '
      '(constatId=$constatId accepted=$accepted)',
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerUid)
          .collection('notifications')
          .doc(notificationId)
          .set({
            'id': notificationId,
            'userId': ownerUid,
            'type': 'constat_response',
            'title': title,
            'body': body,
            'constatId': constatId,
            'ownerUid': ownerUid,
            'read': false,
            'createdAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));

      debugPrint(
        '[NotifResponse] SUCCESS — $notificationId written for owner $ownerUid '
        '(constat=$constatId accepted=$accepted)',
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        debugPrint(
          '[NotifResponse] PERMISSION_DENIED — $notificationId for $ownerUid. '
          'Check Firestore rules: allow create, update must be set for '
          'users/{userId}/notifications/{notifId}.',
        );
      } else {
        debugPrint('[NotifResponse] ERROR — FirebaseException: ${e.code} ${e.message}');
      }
    } catch (e) {
      debugPrint('[NotifResponse] ERROR — $e');
    }
  }

  /// Mirror an accepted constat to the top-level approved_constats collection.
  Future<void> _mirrorConstatToApproved(Constat constat) async {
    try {
      final data = <String, dynamic>{
        ...constat.toJson(),
        'ownerUid': constat.userId,
        'approverUid': constat.approvalRequestedToUid,
        'mirroredAt': DateTime.now().toIso8601String(),
        'approvalStatus': 'accepted',
      };

      await FirebaseFirestore.instance
          .collection('approved_constats')
          .doc(constat.id)
          .set(data, SetOptions(merge: true));

      debugPrint('Mirrored constat ${constat.id} to approved_constats');
    } catch (e) {
      debugPrint('Error mirroring constat to approved_constats: $e');
    }
  }

  /// Remove a rejected constat mirror from approved_constats if it exists.
  Future<void> _removeApprovedMirror(String constatId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('approved_constats')
          .doc(constatId)
          .get();

      if (doc.exists) {
        await FirebaseFirestore.instance
            .collection('approved_constats')
            .doc(constatId)
            .delete();
        debugPrint('Removed approved_constats mirror for $constatId');
      }
    } catch (e) {
      debugPrint('Error removing approved_constats mirror: $e');
    }
  }

  /// Check if Party B information is complete
  bool isPartyBInfoComplete(Constat constat) {
    if (constat.partyBDriverSnapshot == null ||
        constat.partyBVehicleSnapshot == null ||
        constat.partyBInsuranceSnapshot == null) {
      return false;
    }

    // Check driver info
    final driverFullName = constat.partyBDriverSnapshot?['fullName'] as String?;
    final driverLicenseNumber =
        constat.partyBDriverSnapshot?['licenseNumber'] as String?;
    if (driverFullName == null ||
        driverFullName.isEmpty ||
        driverLicenseNumber == null ||
        driverLicenseNumber.isEmpty) {
      return false;
    }

    // Check vehicle info
    final vehiclePlateNumber =
        constat.partyBVehicleSnapshot?['plateNumber'] as String?;
    final vehicleBrand = constat.partyBVehicleSnapshot?['brand'] as String?;
    if (vehiclePlateNumber == null ||
        vehiclePlateNumber.isEmpty ||
        vehicleBrand == null ||
        vehicleBrand.isEmpty) {
      return false;
    }

    // Check insurance info
    final insuranceNumber =
        constat.partyBInsuranceSnapshot?['insuranceNumber'] as String?;
    final companyName =
        constat.partyBInsuranceSnapshot?['companyName'] as String?;
    if (insuranceNumber == null ||
        insuranceNumber.isEmpty ||
        companyName == null ||
        companyName.isEmpty) {
      return false;
    }

    return true;
  }

  /// Save Party B driver information
  Future<bool> savePartyBDriverInfo({
    required String constatId,
    required String fullName,
    required String licenseNumber,
    required String nationalId,
    required String phoneNumber,
  }) async {
    try {
      final constat = getConstatById(constatId);
      if (constat == null) {
        debugPrint('Constat not found: $constatId');
        return false;
      }

      final now = DateTime.now();
      final driverSnapshot = <String, dynamic>{
        'fullName': fullName,
        'licenseNumber': licenseNumber,
        'nationalId': nationalId.isEmpty ? null : nationalId,
        'phoneNumber': phoneNumber,
      };

      final updatedConstat = constat.copyWith(
        partyBDriverSnapshot: driverSnapshot,
        updatedAt: now,
      );

      // Update local state
      state = state.copyWith(constats: _upsertConstat(updatedConstat));

      // Save to Firestore
      await _saveConstatToFirestore(updatedConstat);

      debugPrint('Saved Party B driver info for constat $constatId');
      return true;
    } catch (e) {
      debugPrint('Error saving Party B driver info: $e');
      return false;
    }
  }

  /// Save Party B vehicle information
  Future<bool> savePartyBVehicleInfo({
    required String constatId,
    required String plateNumber,
    required String brand,
    required String model,
    required String vin,
  }) async {
    try {
      final constat = getConstatById(constatId);
      if (constat == null) {
        debugPrint('Constat not found: $constatId');
        return false;
      }

      final now = DateTime.now();
      final vehicleSnapshot = <String, dynamic>{
        'plateNumber': plateNumber,
        'brand': brand,
        'model': model,
        'vin': vin,
      };

      final updatedConstat = constat.copyWith(
        partyBVehicleSnapshot: vehicleSnapshot,
        updatedAt: now,
      );

      // Update local state
      state = state.copyWith(constats: _upsertConstat(updatedConstat));

      // Save to Firestore
      await _saveConstatToFirestore(updatedConstat);

      debugPrint('Saved Party B vehicle info for constat $constatId');
      return true;
    } catch (e) {
      debugPrint('Error saving Party B vehicle info: $e');
      return false;
    }
  }

  /// Save Party B insurance information and mark completion
  Future<bool> savePartyBInsuranceInfo({
    required String constatId,
    required String insuranceNumber,
    required String companyName,
    required String policyHolderName,
    required String policyType,
  }) async {
    try {
      final constat = getConstatById(constatId);
      if (constat == null) {
        debugPrint('Constat not found: $constatId');
        return false;
      }

      final now = DateTime.now();
      final insuranceSnapshot = <String, dynamic>{
        'insuranceNumber': insuranceNumber,
        'companyName': companyName,
        'policyHolderName': policyHolderName,
        'policyType': policyType.isEmpty ? null : policyType,
      };

      final updatedConstat = constat.copyWith(
        partyBInsuranceSnapshot: insuranceSnapshot,
        partyBCompletedAt: now,
        partyBCompletedByUid: state.currentUser.id,
        updatedAt: now,
      );

      // Update local state
      state = state.copyWith(constats: _upsertConstat(updatedConstat));

      // Save to Firestore
      await _saveConstatToFirestore(updatedConstat);

      debugPrint('Saved Party B insurance info for constat $constatId');
      return true;
    } catch (e) {
      debugPrint('Error saving Party B insurance info: $e');
      return false;
    }
  }

  void _setActiveConstat(Constat constat) {
    state = state.copyWith(
      activeConstat: constat,
      constats: _upsertConstat(constat),
    );

    // Save to Firestore asynchronously
    _saveConstatToFirestore(constat);
  }

  List<DocumentScan> _upsertScan(DocumentScan scan) {
    final scans = [...state.scans];
    final index = scans.indexWhere((item) => item.id == scan.id);
    if (index == -1) {
      scans.insert(0, scan);
    } else {
      scans[index] = scan;
    }
    return List<DocumentScan>.unmodifiable(scans);
  }

  List<InsuranceProfile> _upsertInsuranceProfile(InsuranceProfile profile) {
    final profiles = [...state.insuranceProfiles];
    final index = profiles.indexWhere((item) => item.id == profile.id);
    if (index == -1) {
      profiles.insert(0, profile);
    } else {
      profiles[index] = profile;
    }
    return List<InsuranceProfile>.unmodifiable(profiles);
  }

  List<VehicleProfile> _upsertVehicleProfile(VehicleProfile profile) {
    final profiles = [...state.vehicleProfiles];
    final index = profiles.indexWhere((item) => item.id == profile.id);
    if (index == -1) {
      profiles.insert(0, profile);
    } else {
      profiles[index] = profile;
    }
    return List<VehicleProfile>.unmodifiable(profiles);
  }

  List<DriverProfile> _upsertDriverProfile(DriverProfile profile) {
    final profiles = [...state.driverProfiles];
    final index = profiles.indexWhere((item) => item.id == profile.id);
    if (index == -1) {
      profiles.insert(0, profile);
    } else {
      profiles[index] = profile;
    }
    return List<DriverProfile>.unmodifiable(profiles);
  }

  List<Constat> _upsertConstat(Constat constat) {
    final constats = [...state.constats];
    final index = constats.indexWhere((item) => item.id == constat.id);
    if (index == -1) {
      constats.insert(0, constat);
    } else {
      constats[index] = constat;
    }
    return List<Constat>.unmodifiable(constats);
  }

  List<String> _mergeUnique(List<String> current, Iterable<String> additions) {
    return List<String>.unmodifiable(<String>{
      ...current,
      ...additions.where((value) => value.isNotEmpty),
    });
  }

  String _composeDamageNote(String? currentNote, String evidenceNote) {
    final baseNote = _damageBaseNote(currentNote);
    final trimmedEvidence = evidenceNote.trim();

    if (trimmedEvidence.isEmpty) {
      return '$baseNote Visual evidence linked from recent scans.';
    }

    return '$baseNote Evidence note:\n$trimmedEvidence';
  }

  String _damageBaseNote(String? currentNote) {
    var note = currentNote?.trim();
    if (note == null || note.isEmpty) {
      return 'Incident drafted from mobile flow.';
    }

    final evidenceIndex = note.indexOf('Evidence note:');
    if (evidenceIndex != -1) {
      note = note.substring(0, evidenceIndex).trim();
    }

    note = note
        .replaceFirst(
          RegExp(r'\s*Visual evidence linked from recent scans\.\s*$'),
          '',
        )
        .trim();

    return note.isEmpty ? 'Incident drafted from mobile flow.' : note;
  }

  InsuranceProfile _buildInsuranceProfile({
    required String scanId,
    required Map<String, dynamic> extractedData,
    required DateTime now,
  }) {
    final existing = state.mainInsuranceProfile;

    return (existing ??
            InsuranceProfile(
              id: _id('insurance'),
              userId: state.currentUser.id,
              insuranceNumber:
                  extractedData['insuranceNumber'] as String? ?? '',
              companyName: extractedData['insuranceCompany'] as String? ?? '',
              isPrimary: true,
              verificationStatus: ProfileVerificationStatus.extracted,
              createdAt: now,
              updatedAt: now,
            ))
        .copyWith(
          insuranceNumber: extractedData['insuranceNumber'] as String?,
          companyName: extractedData['insuranceCompany'] as String?,
          policyHolderName: extractedData['ownerName'] as String?,
          policyType: extractedData['policyType'] as String?,
          documentScanId: scanId,
          isPrimary: true,
          verificationStatus: ProfileVerificationStatus.extracted,
          updatedAt: now,
        );
  }

  VehicleProfile _buildVehicleProfile({
    required String scanId,
    required String insuranceProfileId,
    required Map<String, dynamic> extractedData,
    required DateTime now,
  }) {
    final existing = state.mainVehicleProfile;

    return (existing ??
            VehicleProfile(
              id: _id('vehicle'),
              userId: state.currentUser.id,
              plateNumber: extractedData['plateNumber'] as String? ?? '',
              isPrimary: true,
              verificationStatus: ProfileVerificationStatus.extracted,
              createdAt: now,
              updatedAt: now,
            ))
        .copyWith(
          insuranceProfileId: insuranceProfileId,
          plateNumber: extractedData['plateNumber'] as String?,
          vin: extractedData['vin'] as String?,
          brand: extractedData['brand'] as String?,
          model: extractedData['model'] as String?,
          registrationDocumentScanId: scanId,
          isPrimary: true,
          verificationStatus: ProfileVerificationStatus.extracted,
          updatedAt: now,
        );
  }

  DriverProfile _buildDriverProfile({
    required String scanId,
    required Map<String, dynamic> extractedData,
    required DateTime now,
  }) {
    final existing = state.mainDriverProfile;

    return (existing ??
            DriverProfile(
              id: _id('driver'),
              userId: state.currentUser.id,
              fullName: extractedData['driverFullName'] as String? ?? '',
              isPrimary: true,
              verificationStatus: ProfileVerificationStatus.extracted,
              createdAt: now,
              updatedAt: now,
            ))
        .copyWith(
          fullName: extractedData['driverFullName'] as String?,
          licenseNumber: extractedData['driverLicenseNumber'] as String?,
          driverDocumentScanId: scanId,
          phoneNumber: extractedData['driverPhoneNumber'] as String?,
          isPrimary: true,
          verificationStatus: ProfileVerificationStatus.extracted,
          updatedAt: now,
        );
  }

  String _id(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }

  Constat? getConstatById(String id) {
    try {
      return state.constats.firstWhere((constat) => constat.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> discardActiveDraft() async {
    final draft = state.activeConstat;
    if (draft == null || draft.status != ConstatStatus.draft) return;

    final updatedConstats =
        state.constats.where((c) => c.id != draft.id).toList();

    state = state.copyWith(
      constats: updatedConstats,
      clearActiveConstat: true,
    );

    final userId = draft.userId;
    if (userId.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('constats')
          .doc(draft.id)
          .delete();
      debugPrint('Discarded draft ${draft.id} from Firestore');
    } catch (e) {
      debugPrint('Error discarding draft from Firestore: $e');
    }
  }

  String _constatReference(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final suffix = dateTime.millisecond.toString().padLeft(3, '0');
    return 'CS-$year$month$day-$suffix';
  }
}

class AppSessionState {
  const AppSessionState({
    required this.currentUser,
    this.insuranceProfiles = const <InsuranceProfile>[],
    this.vehicleProfiles = const <VehicleProfile>[],
    this.driverProfiles = const <DriverProfile>[],
    this.scans = const <DocumentScan>[],
    this.constats = const <Constat>[],
    this.activeScan,
    this.activeConstat,
  });

  final UserProfile currentUser;
  final List<InsuranceProfile> insuranceProfiles;
  final List<VehicleProfile> vehicleProfiles;
  final List<DriverProfile> driverProfiles;
  final List<DocumentScan> scans;
  final List<Constat> constats;
  final DocumentScan? activeScan;
  final Constat? activeConstat;

  InsuranceProfile? get mainInsuranceProfile {
    final profileId = currentUser.mainInsuranceProfileId;
    if (profileId == null) return null;
    return insuranceProfiles
        .where((profile) => profile.id == profileId)
        .firstOrNull;
  }

  VehicleProfile? get mainVehicleProfile {
    final profileId = currentUser.mainVehicleProfileId;
    if (profileId == null) return null;
    return vehicleProfiles
        .where((profile) => profile.id == profileId)
        .firstOrNull;
  }

  DriverProfile? get mainDriverProfile {
    final profileId = currentUser.mainDriverProfileId;
    if (profileId == null) return null;
    return driverProfiles
        .where((profile) => profile.id == profileId)
        .firstOrNull;
  }

  List<HistoryItem> get historyItems {
    final items = [
      ...scans.map(HistoryItem.fromDocumentScan),
      ...constats.map(HistoryItem.fromConstat),
    ];

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<HistoryItem>.unmodifiable(items);
  }

  AppSessionState copyWith({
    UserProfile? currentUser,
    List<InsuranceProfile>? insuranceProfiles,
    List<VehicleProfile>? vehicleProfiles,
    List<DriverProfile>? driverProfiles,
    List<DocumentScan>? scans,
    List<Constat>? constats,
    DocumentScan? activeScan,
    bool clearActiveScan = false,
    Constat? activeConstat,
    bool clearActiveConstat = false,
  }) {
    return AppSessionState(
      currentUser: currentUser ?? this.currentUser,
      insuranceProfiles: insuranceProfiles ?? this.insuranceProfiles,
      vehicleProfiles: vehicleProfiles ?? this.vehicleProfiles,
      driverProfiles: driverProfiles ?? this.driverProfiles,
      scans: scans ?? this.scans,
      constats: constats ?? this.constats,
      activeScan: clearActiveScan ? null : activeScan ?? this.activeScan,
      activeConstat: clearActiveConstat
          ? null
          : activeConstat ?? this.activeConstat,
    );
  }
}
