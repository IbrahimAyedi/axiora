// classe feha kol route names w paths mte3 application
// nesta3mlouha bech navigation tkoun organized w ma n3awdouch fi kol balasa
abstract final class RouteNames {
  // names mte3 routes, nesta3mlouhom ki n7ebbou na3melo navigation bel name
  static const splash = 'splash';
  static const login = 'login';
  static const register = 'register';
  static const home = 'home';
  static const scan = 'scan';
  static const ocrTest = 'ocr-test';
  static const scanCarteGrise = 'scan-carte-grise';
  static const carteGriseResult = 'carte-grise-result';
  static const carteGriseAutofill = 'carte-grise-autofill';
  static const scanPermis = 'scan-permis';
  static const permisResult = 'permis-result';
  static const scanAssurance = 'scan-assurance';
  static const assuranceResult = 'assurance-result';
  static const preview = 'preview';
  static const processing = 'processing';
  static const result = 'result';
  static const history = 'history';
  static const profile = 'profile';
  static const settings = 'settings';
  static const about = 'about';
  static const constatIntro = 'constat-intro';
  static const accidentInfo = 'accident-info';
  static const driverInfo = 'driver-info';
  static const vehicleInfo = 'vehicle-info';
  static const insuranceInfo = 'insurance-info';
  static const photosDamage = 'photos-damage';
  static const constatReview = 'constat-review';
  static const constatSignature = 'constat-signature';
  static const constatSuccess = 'constat-success';
  static const constatDetail = 'constat-detail';
  static const notifications = 'notifications';
  static const adminDashboard = 'admin-dashboard';
  static const adminConstatDetail = 'admin-constat-detail';
  static const adminUsers = 'admin-users';
  static const adminApprovedReports = 'admin-approved-reports';

  // paths mte3 routes, houma URLs eli yesta3melhom GoRouter
  static const splashPath = '/';
  static const loginPath = '/login';
  static const registerPath = '/register';
  static const homePath = '/home';
  static const scanPath = '/scan';
  static const ocrTestPath = '/ocr-test';
  static const scanCarteGrisePath = '/scan-carte-grise';
  static const carteGriseResultPath = '/carte-grise-result';
  static const carteGriseAutofillPath = '/carte-grise-autofill';
  static const scanPermisPath = '/scan-permis';
  static const permisResultPath = '/permis-result';
  static const scanAssurancePath = '/scan-assurance';
  static const assuranceResultPath = '/assurance-result';
  static const previewPath = '/preview';
  static const processingPath = '/processing';
  static const resultPath = '/result';
  static const historyPath = '/history';
  static const profilePath = '/profile';
  static const settingsPath = '/settings';
  static const aboutPath = '/about';
  static const constatIntroPath = '/constat';
  static const accidentInfoPath = '/constat/accident-info';
  static const driverInfoPath = '/constat/driver-info';
  static const vehicleInfoPath = '/constat/vehicle-info';
  static const insuranceInfoPath = '/constat/insurance-info';
  static const photosDamagePath = '/constat/photos-damage';
  static const constatReviewPath = '/constat/review';
  static const constatSignaturePath = '/constat/signature';
  static const constatSuccessPath = '/constat/success';
  static const notificationsPath = '/notifications';
  static const adminDashboardPath = '/admin';
  static const adminUsersPath = '/admin/users';
  static const adminApprovedReportsPath = '/admin/approved-reports';
  // function ta3mel path mte3 detail constat
  // ownerUid optionnel, nesta3mlouh ki User B yhel constat mte3 User A
  static String constatDetailPath(String id, {String? ownerUid}) {
    if (ownerUid != null && ownerUid.isNotEmpty) {
      return '/history/constat/$id?ownerUid=$ownerUid';
    }
    return '/history/constat/$id';
  }

  // function ta3mel path mte3 partyB info
  // ownerUid y5alli app ta3ref constat taba3 ay user
  static String partyBInfoPath(String constatId, {String? ownerUid}) {
    if (ownerUid != null && ownerUid.isNotEmpty) {
      return '/history/constat/$constatId/party-b-info?ownerUid=$ownerUid';
    }
    return '/history/constat/$constatId/party-b-info';
  }

  // function ta3mel path mte3 admin detail constat
  static String adminConstatDetailPath(String id) => '/admin/constat/$id';
}
