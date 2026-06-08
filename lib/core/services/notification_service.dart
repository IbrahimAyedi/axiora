// service simple mte3 notifications settings
class NotificationService {
  // private constructor bech nesta3mlou singleton pattern
  NotificationService._();

  // instance wa7da men NotificationService fi kol app
  static final NotificationService instance = NotificationService._();

  // state local: notifications enabled wala disabled
  bool _isEnabled = true;

  // initialization mte3 notification service
  Future<void> initialize() async {
    // TODO: ba3ed najmou nconnectiw local notifications wala push notifications
  }

  // getter yrajja3 notifications enabled wala le
  bool get isEnabled => _isEnabled;

  // tbadel notification setting
  void setEnabled(bool value) {
    _isEnabled = value;
  }
}
