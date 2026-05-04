class PasswordValidator {
  
  static bool hasMinLength(String password) {
    return password.length >= 6;
  }
  
  static bool hasUppercase(String password) {
    return password.contains(RegExp(r'[A-Z]'));
  }
  
  static bool hasNumber(String password) {
    return password.contains(RegExp(r'[0-9]'));
  }
  
  static bool hasSymbol(String password) {
    // Cek apakah ada karakter selain huruf dan angka
    return password.contains(RegExp(r'[^a-zA-Z0-9]'));
  }
  
  static bool isValid(String password) {
    return hasMinLength(password) && 
           hasUppercase(password) && 
           hasNumber(password) && 
           hasSymbol(password);
  }
  
  static List<Map<String, dynamic>> getCriteria(String password) {
    return [
      {'label': 'Minimal 6 karakter', 'met': hasMinLength(password)},
      {'label': 'Mengandung huruf kapital', 'met': hasUppercase(password)},
      {'label': 'Mengandung angka', 'met': hasNumber(password)},
      {'label': 'Mengandung simbol', 'met': hasSymbol(password)},
    ];
  }
}