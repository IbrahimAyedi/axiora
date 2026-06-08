// classe feha constants globales mte3 application

abstract final class AppConstants {
  // esm application eli yban fi MaterialApp w UI

  static const appName = 'Smart Constat';
  static const appTagline = 'Digital vehicle inspection and accident reporting';
  // default language mte3 app

  static const defaultLocale = 'en';
  // description mte3 application
  static const appDescription =
      'A mobile-first assistant for document scanning, online accident reports, and future insurance claim workflows.';
  // email support mte3 application
  static const supportEmail = 'support@smartconstat.app';
  static const fakeUserName = 'Mohamed';
  // fake OCR text lel demo/testing

  static const fakeOcrText = '123 TUN 456';
  static const fakeImageLabel = 'Vehicle detected';
  static const fakeValidationScore = '82%';
  static const fakeSummary =
      'Plate text recognized successfully. Image quality is good enough for review and export.';
  static const fakeCarteGriseOwner = 'Mohamed Ben Ali';
  static const fakeCarteGriseBrand = 'Peugeot';
  static const fakeCarteGriseModel = '208';
  static const fakeCarteGriseVin = 'VF3XXXXXXXXXXXX';
  static const fakeConstatReference = 'CS-2026-0412';

  static const connectTimeoutInSeconds = 30;
  static const receiveTimeoutInSeconds = 30;
}
