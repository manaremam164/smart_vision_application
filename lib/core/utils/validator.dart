typedef Validator = String? Function(String?);

class Validators {
  static Validator use(List<Validator> validators) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) {
          return error;
        }
      }
      return null;
    };
  }

  static String? isValidEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email cannot be empty';
    }
    const emailRegex = r'^[^@]+@[^@]+\.[^@]+';
    if (!RegExp(emailRegex).hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? isNotEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return 'Field cannot be empty';
    }
    return null;
  }

  static String? isValidPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    // final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    // final hasSymbol = RegExp(r'[!@#$%^&*]').hasMatch(value);
    // if (!hasLetter || !hasSymbol) {
    //   return 'Password must have at least one letter and one symbol';
    // }

    return null;
  }

  static String? isValidName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name cannot be empty';
    }
    return null;
  }

  static String? isValidPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone cannot be empty';
    }
    return null;
  }

  static String? isValidAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address cannot be empty';
    }
    return null;
  }

  static String? isValidDouble(String? value) {
    if (value == null || value.isEmpty) {
      return 'Number cannot be empty';
    }

    if (double.tryParse(value) == null) {
      return 'Enter a valid number';
    }

    return null;
  }

  static String? isValidInt(String? value) {
    if (value == null || value.isEmpty) {
      return 'Number cannot be empty';
    }

    if (int.tryParse(value) == null) {
      return 'Enter a valid number';
    }

    return null;
  }
}
