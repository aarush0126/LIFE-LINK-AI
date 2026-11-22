class Validators {
  Validators._();

  static String? requiredField(String? value, [String message = 'This field is required']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(?:\.[\w-]+)+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid institutional email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? hprId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Healthcare Professional ID (HPR) is required';
    }
    // HPR ID format e.g. 14 digits or alphanumeric standard
    if (value.trim().length < 6) {
      return 'Enter a valid National HPR ID';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contact number is required';
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{10,14}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'\s+|-'), ''))) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}
