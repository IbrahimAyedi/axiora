// classe feha validators mte3 forms
// nesta3mlouha bech nvalidiw inputs kif email, phone, password...
abstract final class Validators {
  // validator mte3 required field
  static String? requiredField(String? value, {String label = 'This field'}) {
    // ken value fergha, nraj3ou error message
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }

    // null ya3ni input s7i7
    return null;
  }

  // validator mte3 email
  static String? email(String? value) {
    // email obligatoire
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    // pattern simple bech nverifiw format email
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    // ken format ghalet, nraj3ou error
    if (!emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email';
    }

    // null ya3ni email s7i7
    return null;
  }

  // validator mte3 phone number
  static String? phone(String? value) {
    // phone obligatoire
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // nverifiw minimum length
    if (value.trim().length < 8) {
      return 'Phone number looks too short';
    }

    // null ya3ni phone s7i7
    return null;
  }

  // validator mte3 password
  static String? password(String? value) {
    // password obligatoire
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    // minimum 6 characters
    if (value.length < 6) {
      return 'Use at least 6 characters';
    }

    // null ya3ni password s7i7
    return null;
  }

  // validator mte3 confirm password
  static String? confirmPassword(String? value, String original) {
    // awel haja nverifiw password kif validator normal
    final passwordValidation = password(value);

    // ken fama error, nraj3ouha
    if (passwordValidation != null) {
      return passwordValidation;
    }

    // nverifiw password w confirmation kif kif
    if (value != original) {
      return 'Passwords do not match';
    }

    // null ya3ni confirm password s7i7
    return null;
  }
}
