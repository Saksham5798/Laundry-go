// Schedule screen — Modern, highly interactive scheduling flow.
// Features quick day selector chips, 1-tap time slots, express/standard delivery toggles,
// address type choice chips, and a 1-click "Use Demo Address" button for viva demos.
// Styled to the dark theme system (#070D1D, #17233A, #25BDF2).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/index.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/centered_content.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _formKey = GlobalKey<FormState>();

  // Date/time state
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  DateTime? _deliveryDate;
  TimeOfDay? _deliveryTime;

  // Address controllers
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl   = TextEditingController();
  AddressType _addressType = AddressType.home;

  // Errors
  String? _pickupError;
  String? _deliveryError;

  @override
  void initState() {
    super.initState();
    // Default sensible selection: Tomorrow at 10:00 AM, Delivery 2 days later at 10:00 AM
    final now = DateTime.now();
    _pickupDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    _pickupTime = const TimeOfDay(hour: 10, minute: 0);
    _deliveryDate = _pickupDate!.add(const Duration(days: 2));
    _deliveryTime = const TimeOfDay(hour: 10, minute: 0);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _fillDemoAddress() {
    setState(() {
      _nameCtrl.text = 'Saksham Malhotra';
      _phoneCtrl.text = '9876543210';
      _addressCtrl.text = 'Flat 402, Block B, Silver Palms Apts, Ring Road';
      _notesCtrl.text = 'Please ring the doorbell. Delicate clothes marked.';
      _addressType = AddressType.home;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✨ Demo address & contact details filled!'),
        backgroundColor: AppColors.cardElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Date pickers
  Future<void> _pickCustomDate({required bool isPickup}) async {
    final now = DateTime.now();
    final first = isPickup ? now : (_pickupDateTime ?? now).add(const Duration(days: 1));
    final last = isPickup
        ? now.add(const Duration(days: 7))
        : (_pickupDateTime ?? now).add(const Duration(days: 10));

    final picked = await showDatePicker(
      context: context,
      initialDate: first,
      firstDate: first,
      lastDate: last,
    );
    if (picked == null) return;
    setState(() {
      if (isPickup) {
        _pickupDate = picked;
        _pickupError = null;
        if (_deliveryDate != null && _deliveryDate!.isBefore(_pickupDate!.add(const Duration(days: 1)))) {
          _deliveryDate = _pickupDate!.add(const Duration(days: 2));
        }
      } else {
        _deliveryDate = picked;
        _deliveryError = null;
      }
    });
  }

  Future<void> _pickCustomTime({required bool isPickup}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isPickup
          ? (_pickupTime ?? const TimeOfDay(hour: 10, minute: 0))
          : (_deliveryTime ?? const TimeOfDay(hour: 10, minute: 0)),
    );
    if (picked == null) return;
    setState(() {
      if (isPickup) {
        _pickupTime = picked;
        _pickupError = null;
      } else {
        _deliveryTime = picked;
        _deliveryError = null;
      }
    });
  }

  DateTime? get _pickupDateTime {
    if (_pickupDate == null || _pickupTime == null) return null;
    return DateTime(
      _pickupDate!.year, _pickupDate!.month, _pickupDate!.day,
      _pickupTime!.hour, _pickupTime!.minute,
    );
  }

  DateTime? get _deliveryDateTime {
    if (_deliveryDate == null || _deliveryTime == null) return null;
    return DateTime(
      _deliveryDate!.year, _deliveryDate!.month, _deliveryDate!.day,
      _deliveryTime!.hour, _deliveryTime!.minute,
    );
  }

  bool _validateAndSave() {
    bool ok = _formKey.currentState?.validate() ?? false;
    final svc = context.read<OrderProvider>().schedulingService;

    // Pickup validation
    final pickup = _pickupDateTime;
    if (pickup == null) {
      setState(() => _pickupError = 'Select pickup date and time.');
      ok = false;
    } else {
      final err = svc.validatePickup(pickup);
      if (err != null) {
        setState(() => _pickupError = err.message);
        ok = false;
      } else {
        setState(() => _pickupError = null);
      }
    }

    // Delivery validation
    final delivery = _deliveryDateTime;
    if (delivery == null) {
      setState(() => _deliveryError = 'Select delivery date and time.');
      ok = false;
    } else if (pickup != null) {
      final err = svc.validateDelivery(pickup, delivery);
      if (err != null) {
        setState(() => _deliveryError = err.message);
        ok = false;
      } else {
        setState(() => _deliveryError = null);
      }
    }

    return ok;
  }

  void _submit() {
    if (!_validateAndSave()) return;

    final provider = context.read<OrderProvider>();
    provider.setDraftSchedule(
      Schedule(
        pickupDateTime: _pickupDateTime!,
        deliveryDateTime: _deliveryDateTime!,
      ),
    );
    provider.setDraftAddress(
      Address(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        addressLine: _addressCtrl.text.trim(),
        type: _addressType,
        instructions: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ),
    );
    Navigator.pushNamed(context, AppRoutes.summary);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Schedule & Address'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: CenteredContent(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // ==================== SECTION 1: PICKUP ====================
                const _SectionTitle(
                  icon: Icons.local_shipping_outlined,
                  title: '1. Select Pickup Time',
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),

                // Horizontal Day Pills (Next 5 Days)
                SizedBox(
                  height: 74,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    itemBuilder: (context, i) {
                      final day = DateTime(now.year, now.month, now.day).add(Duration(days: i));
                      final isSelected = _pickupDate != null &&
                          _pickupDate!.year == day.year &&
                          _pickupDate!.month == day.month &&
                          _pickupDate!.day == day.day;

                      final dayName = i == 0 ? 'Today' : (i == 1 ? 'Tomorrow' : DateFormat('EEE').format(day));
                      final dateStr = DateFormat('dd MMM').format(day);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _pickupDate = day;
                            _pickupError = null;
                            if (_deliveryDate != null && _deliveryDate!.isBefore(day.add(const Duration(days: 1)))) {
                              _deliveryDate = day.add(const Duration(days: 2));
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 88,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 2 : 1,
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? const Color(0xFF070D1D) : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? const Color(0xFF070D1D) : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Pickup Time Slot Pills
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTimeSlotChip(
                      label: '🌅 09:00 AM',
                      time: const TimeOfDay(hour: 9, minute: 0),
                      isPickup: true,
                    ),
                    _buildTimeSlotChip(
                      label: '☀️ 11:00 AM',
                      time: const TimeOfDay(hour: 11, minute: 0),
                      isPickup: true,
                    ),
                    _buildTimeSlotChip(
                      label: '🌆 02:00 PM',
                      time: const TimeOfDay(hour: 14, minute: 0),
                      isPickup: true,
                    ),
                    _buildTimeSlotChip(
                      label: '🌙 05:00 PM',
                      time: const TimeOfDay(hour: 17, minute: 0),
                      isPickup: true,
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.more_time, size: 16, color: AppColors.primary),
                      label: const Text('Custom Time'),
                      backgroundColor: AppColors.card,
                      side: const BorderSide(color: AppColors.border),
                      labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                      onPressed: () => _pickCustomTime(isPickup: true),
                    ),
                  ],
                ),
                if (_pickupError != null) ...[
                  const SizedBox(height: 8),
                  _ErrorBanner(message: _pickupError!),
                ],

                const SizedBox(height: 28),

                // ==================== SECTION 2: DELIVERY ====================
                const _SectionTitle(
                  icon: Icons.inventory_2_outlined,
                  title: '2. Select Delivery Time',
                  color: AppColors.secondaryLight,
                ),
                const SizedBox(height: 12),

                // Delivery Speed Options: Standard vs Express
                Row(
                  children: [
                    Expanded(
                      child: _buildDeliverySpeedCard(
                        title: '⚡ Express (24h)',
                        subtitle: 'Next day delivery',
                        isSelected: _deliveryDate != null &&
                            _pickupDate != null &&
                            _deliveryDate!.difference(_pickupDate!).inDays <= 1,
                        onTap: () {
                          if (_pickupDate != null) {
                            setState(() {
                              _deliveryDate = _pickupDate!.add(const Duration(days: 1));
                              _deliveryTime = _pickupTime ?? const TimeOfDay(hour: 10, minute: 0);
                              _deliveryError = null;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDeliverySpeedCard(
                        title: '🌿 Standard (48h)',
                        subtitle: 'Thorough care',
                        isSelected: _deliveryDate != null &&
                            _pickupDate != null &&
                            _deliveryDate!.difference(_pickupDate!).inDays >= 2,
                        onTap: () {
                          if (_pickupDate != null) {
                            setState(() {
                              _deliveryDate = _pickupDate!.add(const Duration(days: 2));
                              _deliveryTime = _pickupTime ?? const TimeOfDay(hour: 10, minute: 0);
                              _deliveryError = null;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Delivery Time summary with custom picker
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          _deliveryDate != null && _deliveryTime != null
                              ? 'Delivering: ${DateFormat('EEE, dd MMM').format(_deliveryDate!)} at ${_deliveryTime!.format(context)}'
                              : 'Select delivery date',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => _pickCustomDate(isPickup: false),
                      icon: const Icon(Icons.calendar_today, size: 14),
                      label: const Text('Change Date', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(120, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ],
                ),
                if (_deliveryError != null) ...[
                  const SizedBox(height: 8),
                  _ErrorBanner(message: _deliveryError!),
                ],

                const SizedBox(height: 28),

                // ==================== SECTION 3: ADDRESS ====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionTitle(
                      icon: Icons.location_on_outlined,
                      title: '3. Pickup Address',
                      color: AppColors.warning,
                    ),
                    TextButton.icon(
                      onPressed: _fillDemoAddress,
                      icon: const Icon(Icons.flash_on, size: 16, color: AppColors.warning),
                      label: const Text(
                        'Demo Fill',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Address Type Choice Chips
                Row(
                  children: AddressType.values.map((type) {
                    final isSelected = _addressType == type;
                    IconData icon;
                    switch (type) {
                      case AddressType.home:   icon = Icons.home_outlined; break;
                      case AddressType.office: icon = Icons.work_outline; break;
                      case AddressType.other:  icon = Icons.place_outlined; break;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _addressType = type),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 16,
                                color: isSelected ? const Color(0xFF070D1D) : AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                type.label,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 12,
                                  color: isSelected ? const Color(0xFF070D1D) : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Full Name
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required.' : null,
                ),
                const SizedBox(height: 14),

                // Phone Number
                TextFormField(
                  controller: _phoneCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    prefixText: '+91 ',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Phone is required.';
                    if (v.length != 10) return 'Enter a 10-digit number.';
                    if (!RegExp(r'^[6-9]').hasMatch(v)) return 'Must start with 6–9.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Address Line
                TextFormField(
                  controller: _addressCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Complete Address (House/Flat No, Street, Landmark)',
                    prefixIcon: Icon(Icons.location_city_outlined),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 2,
                  validator: (v) {
                    if (v == null || v.trim().length < 10) {
                      return 'Enter a complete address (≥10 characters).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Special Instructions
                TextFormField(
                  controller: _notesCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Special Delivery Instructions (optional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                    hintText: 'e.g. Leave with security / Ring bell',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 36),

                // Submit CTA
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF070D1D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue to Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotChip({
    required String label,
    required TimeOfDay time,
    required bool isPickup,
  }) {
    final selectedTime = isPickup ? _pickupTime : _deliveryTime;
    final isSelected = selectedTime != null && selectedTime.hour == time.hour && selectedTime.minute == time.minute;

    return InkWell(
      onTap: () {
        setState(() {
          if (isPickup) {
            _pickupTime = time;
            _pickupError = null;
          } else {
            _deliveryTime = time;
            _deliveryError = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            fontSize: 12,
            color: isSelected ? const Color(0xFF070D1D) : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildDeliverySpeedCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
