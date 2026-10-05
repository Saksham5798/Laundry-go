// Luhn algorithm — validates credit/debit card numbers.
// Returns true if the number passes the check, false otherwise.
// Used by MockPaymentGateway and the card form validator.

bool luhnCheck(String digits) {
  if (digits.isEmpty) return false;
  var sum = 0;
  var alternate = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var n = int.tryParse(digits[i]) ?? -1;
    if (n < 0) return false; // non-digit character
    if (alternate) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alternate = !alternate;
  }
  return sum % 10 == 0;
}
