// Payment screen — Modern checkout experience with interactive live credit card preview,
// 1-tap test credentials for quick viva evaluations, UPI app shortcuts, and verified security assurances.
// Styled to the dark theme system (#070D1D, #17233A, #25BDF2).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/index.dart';
import '../core/routes.dart';
import '../core/luhn.dart';
import '../core/theme.dart';
import '../widgets/centered_content.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _method = PaymentMethod.card;
  String? _placedOrderId;

  // UPI
  final _upiCtrl = TextEditingController(text: 'saksham@okhdfcbank');

  // Card
  final _cardFormKey    = GlobalKey<FormState>();
  final _cardNumCtrl    = TextEditingController(text: '4242 4242 4242 4242');
  final _cardExpiryCtrl = TextEditingController(text: '12/28');
  final _cardCvvCtrl    = TextEditingController(text: '123');
  final _cardNameCtrl   = TextEditingController(text: 'SAKSHAM MALHOTRA');

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _cardNumCtrl.addListener(() => setState(() {}));
    _cardExpiryCtrl.addListener(() => setState(() {}));
    _cardNameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _upiCtrl.dispose();
    _cardNumCtrl.dispose();
    _cardExpiryCtrl.dispose();
    _cardCvvCtrl.dispose();
    _cardNameCtrl.dispose();
    super.dispose();
  }

  void _fillValidCard() {
    setState(() {
      _cardNumCtrl.text = '4242 4242 4242 4242';
      _cardExpiryCtrl.text = '12/28';
      _cardCvvCtrl.text = '123';
      _cardNameCtrl.text = 'SAKSHAM MALHOTRA';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✨ Valid Test Card loaded (Luhn Verified)'),
        backgroundColor: AppColors.cardElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _fillDeclineCard() {
    setState(() {
      _cardNumCtrl.text = '4000 0000 0000 0002';
      _cardExpiryCtrl.text = '12/28';
      _cardCvvCtrl.text = '999';
      _cardNameCtrl.text = 'TEST DECLINE';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('⚠️ Decline Test Card loaded (Simulates Gateway Rejection)'),
        backgroundColor: AppColors.cardElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ---- Validation helpers ----
  String? _validateUpi(String? v) {
    if (v == null || v.isEmpty) return 'Enter UPI ID.';
    if (!RegExp(r'^[\w.\-_]{2,256}@[a-zA-Z]{2,64}$').hasMatch(v.trim())) {
      return 'Invalid UPI ID (e.g. user@upi).';
    }
    return null;
  }

  String? _validateCardNumber(String? v) {
    final digits = (v ?? '').replaceAll(' ', '');
    if (digits.length != 16) return 'Enter 16 digits.';
    if (!luhnCheck(digits)) return 'Invalid card number (Luhn check failed).';
    return null;
  }

  String? _validateExpiry(String? v) {
    if (v == null || v.length != 5) return 'Enter MM/YY.';
    final parts = v.split('/');
    if (parts.length != 2) return 'Enter MM/YY.';
    final month = int.tryParse(parts[0]);
    final year  = int.tryParse(parts[1]);
    if (month == null || year == null) return 'Invalid date.';
    if (month < 1 || month > 12) return 'Invalid month.';
    final now = DateTime.now();
    final expiryDate = DateTime(2000 + year, month + 1);
    if (expiryDate.isBefore(DateTime(now.year, now.month))) {
      return 'Card is expired.';
    }
    return null;
  }

  // ---- Pay action ----
  Future<void> _pay() async {
    if (_submitting) return;

    if (_method == PaymentMethod.upi) {
      final err = _validateUpi(_upiCtrl.text);
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
    } else if (_method == PaymentMethod.card) {
      if (!(_cardFormKey.currentState?.validate() ?? false)) return;
    }

    setState(() => _submitting = true);
    _showLoadingDialog();

    final provider = context.read<OrderProvider>();
    final order = await provider.placeOrder(_method);
    setState(() => _placedOrderId = order.id);

    await provider.processPayment(
      orderId: order.id,
      method: _method,
      upiId: _method == PaymentMethod.upi ? _upiCtrl.text.trim() : null,
      cardNumber: _method == PaymentMethod.card ? _cardNumCtrl.text.replaceAll(' ', '') : null,
      cardExpiry: _method == PaymentMethod.card ? _cardExpiryCtrl.text : null,
      cardCvv: _method == PaymentMethod.card ? _cardCvvCtrl.text : null,
      cardName: _method == PaymentMethod.card ? _cardNameCtrl.text.trim() : null,
    );

    if (!mounted) return;
    Navigator.of(context).pop();

    final state = provider.paymentState;
    provider.resetPaymentState();

    if (state == PaymentState.success) {
      await _showSuccessDialog(provider.lastTransactionId ?? '');
    } else {
      await _showFailureDialog(provider.lastPaymentError ?? 'Payment failed.');
    }

    setState(() => _submitting = false);
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 20),
              Text(
                'Contacting Payment Gateway...',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
              ),
              SizedBox(height: 6),
              Text(
                'Please do not close the app',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSuccessDialog(String txnId) async {
    final orderId = _placedOrderId;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppColors.border)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 54),
            ),
            const SizedBox(height: 18),
            const Text(
              'Payment Successful!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your laundry pickup has been scheduled.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Text('Transaction ID', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(
                    txnId,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<OrderProvider>().clearCart();
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.tracking,
                (r) => r.settings.name == AppRoutes.home,
                arguments: orderId,
              );
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppColors.primary,
              foregroundColor: const Color(0xFF070D1D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Track Order Live', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<void> _showFailureDialog(String message) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
        icon: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 50),
        title: const Text('Payment Declined', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Retry with another method'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Payment'),
        centerTitle: true,
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              Expanded(
                child: CenteredContent(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      // Amount to Pay Banner
                      _AmountBanner(total: provider.total),
                      const SizedBox(height: 22),

                      // Payment Method Selector Tabs
                      const Text(
                        'Select Payment Method',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildMethodOption(
                            method: PaymentMethod.card,
                            label: 'Card',
                            icon: Icons.credit_card,
                          ),
                          const SizedBox(width: 8),
                          _buildMethodOption(
                            method: PaymentMethod.upi,
                            label: 'UPI',
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                          const SizedBox(width: 8),
                          _buildMethodOption(
                            method: PaymentMethod.cod,
                            label: 'Cash on Del.',
                            icon: Icons.payments_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Method-specific Content
                      if (_method == PaymentMethod.card) ...[
                        _InteractiveCreditCard(
                          cardNumber: _cardNumCtrl.text,
                          cardHolder: _cardNameCtrl.text,
                          expiry: _cardExpiryCtrl.text,
                        ),
                        const SizedBox(height: 14),

                        // 1-Click Test Helper Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _fillValidCard,
                                icon: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                                label: const Text('Test Card (Success)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _fillDeclineCard,
                                icon: const Icon(Icons.block, size: 16, color: AppColors.error),
                                label: const Text('Test Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Card Input Fields
                        _CardForm(
                          formKey: _cardFormKey,
                          numCtrl: _cardNumCtrl,
                          expiryCtrl: _cardExpiryCtrl,
                          cvvCtrl: _cardCvvCtrl,
                          nameCtrl: _cardNameCtrl,
                          validateCardNumber: _validateCardNumber,
                          validateExpiry: _validateExpiry,
                        ),
                      ] else if (_method == PaymentMethod.upi) ...[
                        _UpiSection(
                          ctrl: _upiCtrl,
                          onSelectShortcut: (v) => setState(() => _upiCtrl.text = v),
                        ),
                      ] else ...[
                        const _CodSection(),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Sticky Pay Button Bar
              _PayBar(
                method: _method,
                total: provider.total,
                submitting: _submitting,
                onPay: _pay,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMethodOption({
    required PaymentMethod method,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _method == method;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _method = method),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: isSelected ? const Color(0xFF070D1D) : AppColors.primary),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? const Color(0xFF070D1D) : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Live Virtual Credit Card ----
class _InteractiveCreditCard extends StatelessWidget {
  final String cardNumber;
  final String cardHolder;
  final String expiry;

  const _InteractiveCreditCard({
    required this.cardNumber,
    required this.cardHolder,
    required this.expiry,
  });

  @override
  Widget build(BuildContext context) {
    final displayNum = cardNumber.isEmpty ? '•••• •••• •••• ••••' : cardNumber;
    final displayName = cardHolder.isEmpty ? 'YOUR NAME HERE' : cardHolder;
    final displayExpiry = expiry.isEmpty ? 'MM/YY' : expiry;

    return Container(
      height: 195,
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F1B35), Color(0xFF1B2B48), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Golden Chip + Contactless icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAB308),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Container(
                    width: 32,
                    height: 22,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.contactless, color: Colors.white70, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'LaundryCard',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),

          // Card Number
          Text(
            displayNum,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.2,
              fontFamily: 'Courier',
            ),
          ),

          // Bottom Row: Cardholder & Expiry
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CARD HOLDER', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    displayName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('EXPIRES', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    displayExpiry,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountBanner extends StatelessWidget {
  final double total;
  const _AmountBanner({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 22, color: AppColors.primary),
              SizedBox(width: 10),
              Text(
                'Total Payable',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
              ),
            ],
          ),
          Text(
            '₹${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController numCtrl;
  final TextEditingController expiryCtrl;
  final TextEditingController cvvCtrl;
  final TextEditingController nameCtrl;
  final FormFieldValidator<String> validateCardNumber;
  final FormFieldValidator<String> validateExpiry;

  const _CardForm({
    required this.formKey,
    required this.numCtrl,
    required this.expiryCtrl,
    required this.cvvCtrl,
    required this.nameCtrl,
    required this.validateCardNumber,
    required this.validateExpiry,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: numCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Card Number',
              hintText: '4242 4242 4242 4242',
              prefixIcon: Icon(Icons.credit_card),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberFormatter(),
            ],
            validator: validateCardNumber,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: expiryCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Expiry (MM/YY)',
                    prefixIcon: Icon(Icons.date_range_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _ExpiryFormatter(),
                  ],
                  validator: validateExpiry,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: cvvCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  validator: (v) => (v == null || v.length != 3) ? '3 digits required.' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: nameCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Name on Card',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required.' : null,
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted),
              SizedBox(width: 6),
              Text(
                '256-bit Mock Encrypted. Card info is never stored.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpiSection extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onSelectShortcut;

  const _UpiSection({required this.ctrl, required this.onSelectShortcut});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick UPI Apps', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildUpiAppChip('Google Pay', 'user@okaxis'),
            const SizedBox(width: 8),
            _buildUpiAppChip('PhonePe', 'user@ybl'),
            const SizedBox(width: 8),
            _buildUpiAppChip('Paytm', 'user@paytm'),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'UPI ID',
            hintText: 'username@bank',
            prefixIcon: Icon(Icons.alternate_email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildUpiAppChip(String appName, String sampleId) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => onSelectShortcut(sampleId),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          backgroundColor: AppColors.card,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(appName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
    );
  }
}

class _CodSection extends StatelessWidget {
  const _CodSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payments_rounded, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cash on Delivery',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  'Pay via Cash or UPI when your clean laundry is delivered to your doorstep.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayBar extends StatelessWidget {
  final PaymentMethod method;
  final double total;
  final bool submitting;
  final VoidCallback onPay;

  const _PayBar({
    required this.method,
    required this.total,
    required this.submitting,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final label = method == PaymentMethod.cod
        ? 'Place Order (Pay on Delivery)'
        : 'Pay ₹${total.toStringAsFixed(2)} Securely';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: FilledButton(
          onPressed: submitting ? null : onPay,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: const Color(0xFF070D1D),
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: submitting
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF070D1D)),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 18),
                    const SizedBox(width: 8),
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ],
                ),
        ),
      ),
    );
  }
}

// Formatters
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final out = buffer.toString();
    return newValue.copyWith(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final out = buffer.toString();
    return newValue.copyWith(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}
