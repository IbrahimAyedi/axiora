import '../../../../app/config/app_constants.dart';
import '../models/carte_grise_data.dart';

// service placeholder mte3 OCR carte grise
// يرجع fake data lel demo/testing, moch OCR reel
class CarteGriseOcrPlaceholderService {
  const CarteGriseOcrPlaceholderService();

  // function tرجع mock carte grise data ba3d delay sghir
  Future<CarteGriseData> extractMockData() async {
    // delay bech nimitaw processing mte3 OCR
    await Future<void>.delayed(const Duration(milliseconds: 900));

    // fake data jeya men AppConstants
    return const CarteGriseData(
      plateNumber: AppConstants.fakeOcrText,
      ownerName: AppConstants.fakeCarteGriseOwner,
      brand: AppConstants.fakeCarteGriseBrand,
      model: AppConstants.fakeCarteGriseModel,
      vin: AppConstants.fakeCarteGriseVin,
    );
  }
}
