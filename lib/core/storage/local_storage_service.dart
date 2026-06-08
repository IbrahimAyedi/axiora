// service simple mte3 local storage
class LocalStorageService {
  // private constructor bech nesta3mlou singleton pattern
  LocalStorageService._();

  // instance wa7da men LocalStorageService fi kol app
  static final LocalStorageService instance = LocalStorageService._();

  // memory store simple fi RAM
  // data tetna7a ki app tetسكر wala restart
  static final Map<String, String> _memoryStore = <String, String>{};

  // tsajel string b key mou3ayna
  Future<void> saveString(String key, String value) async {
    _memoryStore[key] = value;
  }

  // ta9ra string b key mou3ayna
  Future<String?> readString(String key) async {
    return _memoryStore[key];
  }
}
