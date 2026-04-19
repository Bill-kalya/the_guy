class Validators {
  // Phone number validation (Kenyan format)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove any spaces or special characters
    final cleanNumber = value.replaceAll(RegExp(r'\s+'), '');
    
    // Kenyan phone number patterns
    final patterns = [
      r'^07[0-9]{8}$',      // 0712345678
      r'^01[0-9]{8}$',      // 0112345678
      r'^2547[0-9]{8}$',    // 254712345678
      r'^2541[0-9]{8}$',    // 254112345678
      r'^\+2547[0-9]{8}$',  // +254712345678
      r'^\+2541[0-9]{8}$',  // +254112345678
    ];
    
    for (final pattern in patterns) {
      if (RegExp(pattern).hasMatch(cleanNumber)) {
        return null;
      }
    }
    
    return 'Enter a valid Kenyan phone number';
  }
  
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }
  
  // OTP validation
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    
    return null;
  }
  
  // Required field validation
  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  // Minimum length validation
  static String? validateMinLength(String? value, int minLength, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    
    return null;
  }
  
  // Maximum length validation
  static String? validateMaxLength(String? value, int maxLength, {String fieldName = 'This field'}) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }
    return null;
  }
  
  // Numeric validation
  static String? validateNumeric(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return '$fieldName must contain only numbers';
    }
    
    return null;
  }
  
  // Decimal validation
  static String? validateDecimal(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) {
      return '$fieldName must be a valid number';
    }
    
    return null;
  }
  
  // Positive number validation
  static String? validatePositiveNumber(String? value, {String fieldName = 'This field'}) {
    final numericError = validateNumeric(value, fieldName: fieldName);
    if (numericError != null) return numericError;
    
    final number = double.tryParse(value!);
    if (number == null || number <= 0) {
      return '$fieldName must be greater than 0';
    }
    
    return null;
  }
  
  // Price validation
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    
    final price = double.tryParse(value);
    if (price == null) {
      return 'Enter a valid price';
    }
    
    if (price < 50) {
      return 'Minimum price is KES 50';
    }
    
    if (price > 100000) {
      return 'Maximum price is KES 100,000';
    }
    
    return null;
  }
  
  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
  
  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  // URL validation
  static String? validateUrl(String? value, {String fieldName = 'URL'}) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }
    
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Enter a valid URL';
    }
    
    return null;
  }
  
  // Name validation (letters, spaces, hyphens, apostrophes)
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(value)) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    if (value.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    
    return null;
  }
  
  // Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    
    if (value.length < 5) {
      return 'Please enter a complete address';
    }
    
    return null;
  }
  
  // Description validation
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    
    if (value.length < 10) {
      return 'Please provide more details (minimum 10 characters)';
    }
    
    if (value.length > 500) {
      return 'Description cannot exceed 500 characters';
    }
    
    return null;
  }
}