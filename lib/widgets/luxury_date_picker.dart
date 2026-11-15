import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/haptic_service.dart';

/// Shared Lumora Birthday / Date Picker with scrollable Month / Day / Year wheels,
/// quick MM/DD/YYYY keyboard input toggle, friendly date formatting, and live 18+ age check.
class LumoraDatePicker {
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _shortMonthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String formatIso(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String formatFriendly(DateTime date) {
    return '${_shortMonthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String formatFull(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  static int computeAge(DateTime dob, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    int age = ref.year - dob.year;
    if (ref.month < dob.month || (ref.month == dob.month && ref.day < dob.day)) {
      age--;
    }
    return age;
  }

  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Parses YYYY-MM-DD, MM/DD/YYYY, or Month DD, YYYY strings.
  static DateTime? tryParse(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final iso = DateTime.tryParse(trimmed);
    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day);
    }

    final slashMatch = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$').firstMatch(trimmed);
    if (slashMatch != null) {
      final month = int.tryParse(slashMatch.group(1)!);
      final day = int.tryParse(slashMatch.group(2)!);
      final year = int.tryParse(slashMatch.group(3)!);
      if (month != null && day != null && year != null) {
        if (month >= 1 && month <= 12 && day >= 1 && day <= daysInMonth(year, month)) {
          return DateTime(year, month, day);
        }
      }
    }

    final wordMatch = RegExp(r'^([A-Za-z]+)\s+(\d{1,2}),?\s+(\d{4})$').firstMatch(trimmed);
    if (wordMatch != null) {
      final monthStr = wordMatch.group(1)!.toLowerCase();
      int? month;
      for (int i = 0; i < 12; i++) {
        if (_monthNames[i].toLowerCase() == monthStr ||
            _shortMonthNames[i].toLowerCase() == monthStr) {
          month = i + 1;
          break;
        }
      }
      final day = int.tryParse(wordMatch.group(2)!);
      final year = int.tryParse(wordMatch.group(3)!);
      if (month != null && day != null && year != null) {
        if (day >= 1 && day <= daysInMonth(year, month)) {
          return DateTime(year, month, day);
        }
      }
    }

    return null;
  }

  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    int? minimumAge,
    String title = 'Select Date of Birth',
    String subtitle = 'Scroll Month, Day & Year or type MM/DD/YYYY',
  }) {
    final now = DateTime.now();
    final minDate = firstDate ?? DateTime(1925, 1, 1);
    final maxDate = lastDate ?? DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final fallback = DateTime(now.year - 20, now.month, now.day);
    var seed = initialDate ?? fallback;
    if (seed.isBefore(minDate)) seed = minDate;
    if (seed.isAfter(maxDate)) seed = maxDate;

    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LumoraDatePickerSheet(
        initialDate: seed,
        minDate: minDate,
        maxDate: maxDate,
        minimumAge: minimumAge,
        title: title,
        subtitle: subtitle,
      ),
    );
  }
}

class _LumoraDatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime minDate;
  final DateTime maxDate;
  final int? minimumAge;
  final String title;
  final String subtitle;

  const _LumoraDatePickerSheet({
    required this.initialDate,
    required this.minDate,
    required this.maxDate,
    this.minimumAge,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_LumoraDatePickerSheet> createState() => _LumoraDatePickerSheetState();
}

class _LumoraDatePickerSheetState extends State<_LumoraDatePickerSheet> {
  late int _year;
  late int _month;
  late int _day;
  bool _manualMode = false;
  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _dayCtrl;
  late FixedExtentScrollController _yearCtrl;
  late TextEditingController _manualCtrl;
  String? _manualError;

  List<int> get _years {
    final count = widget.maxDate.year - widget.minDate.year + 1;
    return List<int>.generate(count, (i) => widget.minDate.year + i);
  }

  @override
  void initState() {
    super.initState();
    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
    _day = widget.initialDate.day;
    _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
    _dayCtrl = FixedExtentScrollController(initialItem: _day - 1);
    _yearCtrl = FixedExtentScrollController(initialItem: (_year - widget.minDate.year).clamp(0, _years.length - 1));
    _manualCtrl = TextEditingController(text: _formatSlash(DateTime(_year, _month, _day)));
  }

  @override
  void dispose() {
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    _yearCtrl.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  String _formatSlash(DateTime d) {
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
  }

  DateTime get _currentDate {
    final maxDay = LumoraDatePicker.daysInMonth(_year, _month);
    final safeDay = _day.clamp(1, maxDay);
    var d = DateTime(_year, _month, safeDay);
    if (d.isBefore(widget.minDate)) d = widget.minDate;
    if (d.isAfter(widget.maxDate)) d = widget.maxDate;
    return d;
  }

  void _syncDayBounds() {
    final maxDay = LumoraDatePicker.daysInMonth(_year, _month);
    if (_day > maxDay) {
      _day = maxDay;
      if (_dayCtrl.hasClients) {
        _dayCtrl.jumpToItem(_day - 1);
      }
    }
    final clamped = _currentDate;
    if (clamped.year != _year || clamped.month != _month || clamped.day != _day) {
      _year = clamped.year;
      _month = clamped.month;
      _day = clamped.day;
      if (_monthCtrl.hasClients) _monthCtrl.jumpToItem(_month - 1);
      if (_dayCtrl.hasClients) _dayCtrl.jumpToItem(_day - 1);
    }
    _manualCtrl.text = _formatSlash(_currentDate);
    _manualError = null;
  }

  void _onManualChanged(String val) {
    final digits = val.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) {
      setState(() {
        _manualError = digits.isEmpty ? 'Enter MM/DD/YYYY' : 'Complete MM/DD/YYYY (${digits.length}/8 digits)';
      });
      return;
    }
    final month = int.tryParse(digits.substring(0, 2)) ?? 0;
    final day = int.tryParse(digits.substring(2, 4)) ?? 0;
    final year = int.tryParse(digits.substring(4, 8)) ?? 0;
    if (month < 1 || month > 12) {
      setState(() => _manualError = 'Month must be between 01 and 12.');
      return;
    }
    if (year < widget.minDate.year || year > widget.maxDate.year) {
      setState(() => _manualError = 'Year must be between ${widget.minDate.year} and ${widget.maxDate.year}.');
      return;
    }
    final maxDay = LumoraDatePicker.daysInMonth(year, month);
    if (day < 1 || day > maxDay) {
      setState(() => _manualError = '${LumoraDatePicker._shortMonthNames[month - 1]} $year only has $maxDay days.');
      return;
    }
    final parsed = DateTime(year, month, day);
    if (parsed.isBefore(widget.minDate) || parsed.isAfter(widget.maxDate)) {
      setState(() => _manualError = 'Please choose a valid past date.');
      return;
    }
    setState(() {
      _manualError = null;
      _year = parsed.year;
      _month = parsed.month;
      _day = parsed.day;
      if (_monthCtrl.hasClients) _monthCtrl.jumpToItem(_month - 1);
      if (_dayCtrl.hasClients) _dayCtrl.jumpToItem(_day - 1);
      if (_yearCtrl.hasClients) {
        _yearCtrl.jumpToItem((_year - widget.minDate.year).clamp(0, _years.length - 1));
      }
    });
  }

  void _toggleMode(bool manual) {
    HapticService.selection();
    setState(() {
      _manualMode = manual;
      if (manual) {
        _manualCtrl.text = _formatSlash(_currentDate);
        _manualError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final selected = _currentDate;
    final age = LumoraDatePicker.computeAge(selected);
    final meetsMinAge = widget.minimumAge == null || age >= widget.minimumAge!;
    final maxDays = LumoraDatePicker.daysInMonth(_year, _month);

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: AppTextStyles.heading(size: 20)),
                        const SizedBox(height: 2),
                        Text(widget.subtitle, style: AppTextStyles.caption(size: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Live selected date preview + Age badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: meetsMinAge ? AppColors.surfaceSoft : AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: meetsMinAge ? AppColors.line : AppColors.dangerBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: meetsMinAge
                            ? AppColors.plum.withValues(alpha: 0.08)
                            : AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.cake_outlined,
                        size: 20,
                        color: meetsMinAge ? AppColors.plum : AppColors.danger,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LumoraDatePicker.formatFull(selected),
                            style: AppTextStyles.body(
                              size: 15,
                              weight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.minimumAge == null
                                ? 'Age: $age years old'
                                : (meetsMinAge
                                    ? '$age years old • Eligible (${widget.minimumAge}+)'
                                    : '$age years old • Must be ${widget.minimumAge}+'),
                            style: AppTextStyles.body(
                              size: 12,
                              weight: FontWeight.w600,
                              color: meetsMinAge ? AppColors.emeraldText : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Mode switcher: Scroll Wheel vs Quick Type
              Row(
                children: [
                  Expanded(
                    child: _ModeTogglePill(
                      label: 'Month • Day • Year',
                      icon: Icons.view_column_rounded,
                      selected: !_manualMode,
                      onTap: () => _toggleMode(false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModeTogglePill(
                      label: 'Quick Type (MM/DD)',
                      icon: Icons.dialpad_rounded,
                      selected: _manualMode,
                      onTap: () => _toggleMode(true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_manualMode)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _manualCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      inputFormatters: [_DateSlashInputFormatter()],
                      onChanged: _onManualChanged,
                      style: AppTextStyles.body(
                        size: 16,
                        weight: FontWeight.w600,
                        color: AppColors.ink,
                        letterSpacing: 1.0,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Enter Date (MM/DD/YYYY)',
                        hintText: '05/15/2001',
                        prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.plum),
                        filled: true,
                        fillColor: Colors.white,
                        errorText: _manualError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.plum, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [1995, 2000, 2003, 2006].map((presetYear) {
                        return ActionChip(
                          label: Text('$presetYear', style: AppTextStyles.body(size: 12, weight: FontWeight.w600)),
                          backgroundColor: AppColors.surfaceSoft,
                          side: const BorderSide(color: AppColors.line),
                          onPressed: () {
                            HapticService.selection();
                            final clampedDay = _day.clamp(1, LumoraDatePicker.daysInMonth(presetYear, _month));
                            setState(() {
                              _year = presetYear;
                              _day = clampedDay;
                              _manualCtrl.text = _formatSlash(DateTime(_year, _month, _day));
                              _manualError = null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                )
              else
                Container(
                  height: 196,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Stack(
                    children: [
                      // Selection band highlight
                      Center(
                        child: Container(
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppColors.plum.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.plum.withValues(alpha: 0.18)),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          // Month wheel
                          Expanded(
                            flex: 5,
                            child: CupertinoPicker(
                              scrollController: _monthCtrl,
                              itemExtent: 40,
                              squeeze: 1.1,
                              selectionOverlay: const SizedBox.shrink(),
                              onSelectedItemChanged: (idx) {
                                HapticService.selection();
                                setState(() {
                                  _month = idx + 1;
                                  _syncDayBounds();
                                });
                              },
                              children: List.generate(12, (idx) {
                                final active = idx + 1 == _month;
                                return Center(
                                  child: Text(
                                    LumoraDatePicker._monthNames[idx],
                                    style: AppTextStyles.body(
                                      size: active ? 14.5 : 13.5,
                                      weight: active ? FontWeight.w700 : FontWeight.w500,
                                      color: active ? AppColors.plum : AppColors.muted,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          // Day wheel
                          Expanded(
                            flex: 2,
                            child: CupertinoPicker(
                              scrollController: _dayCtrl,
                              itemExtent: 40,
                              squeeze: 1.1,
                              selectionOverlay: const SizedBox.shrink(),
                              onSelectedItemChanged: (idx) {
                                HapticService.selection();
                                setState(() {
                                  _day = idx + 1;
                                  _syncDayBounds();
                                });
                              },
                              children: List.generate(maxDays, (idx) {
                                final active = idx + 1 == _day;
                                return Center(
                                  child: Text(
                                    '${idx + 1}',
                                    style: AppTextStyles.body(
                                      size: active ? 15 : 13.5,
                                      weight: active ? FontWeight.w700 : FontWeight.w500,
                                      color: active ? AppColors.plum : AppColors.muted,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          // Year wheel
                          Expanded(
                            flex: 3,
                            child: CupertinoPicker(
                              scrollController: _yearCtrl,
                              itemExtent: 40,
                              squeeze: 1.1,
                              selectionOverlay: const SizedBox.shrink(),
                              onSelectedItemChanged: (idx) {
                                HapticService.selection();
                                setState(() {
                                  _year = _years[idx];
                                  _syncDayBounds();
                                });
                              },
                              children: _years.map((yr) {
                                final active = yr == _year;
                                return Center(
                                  child: Text(
                                    '$yr',
                                    style: AppTextStyles.body(
                                      size: active ? 15 : 13.5,
                                      weight: active ? FontWeight.w700 : FontWeight.w500,
                                      color: active ? AppColors.plum : AppColors.muted,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: (_manualMode && _manualError != null) || !meetsMinAge
                      ? null
                      : () {
                          HapticService.mediumImpact();
                          Navigator.pop(context, _currentDate);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.plum,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.line,
                    disabledForegroundColor: AppColors.muted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    meetsMinAge
                        ? 'Confirm ${LumoraDatePicker.formatFriendly(selected)}'
                        : 'Must be at least ${widget.minimumAge} years old',
                    style: AppTextStyles.body(
                      size: 14,
                      weight: FontWeight.w700,
                      color: ((_manualMode && _manualError != null) || !meetsMinAge)
                          ? AppColors.muted
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTogglePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTogglePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.plum : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.plum : AppColors.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : AppColors.plum),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(
                  size: 12,
                  weight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSlashInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buf = StringBuffer();
    for (int i = 0; i < clipped.length; i++) {
      if (i == 2 || i == 4) buf.write('/');
      buf.write(clipped[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
