import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Configuration class for custom colors in the segmented date picker.
///
/// This class allows developers to selectively override specific colors
/// in the date picker. Any color left as [null] will automatically fall back
/// to the default light or dark theme color based on the context.
class SegmentedPickerColors {
  /// Creates a configuration for custom picker colors.
  const SegmentedPickerColors({
    this.background,
    this.header,
    this.accent,
    this.onAccent,
    this.text,
    this.muted,
    this.tile,
    this.activeTile,
    this.border,
  });

  /// The main background color of the dialog.
  final Color? background;

  /// The background color of the top header section.
  final Color? header;

  /// The primary accent color used for selected dates, active tabs, and primary buttons.
  final Color? accent;

  /// The color of text or icons placed directly on top of the [accent] color.
  final Color? onAccent;

  /// The default color for primary text elements (e.g., standard dates, month names).
  final Color? text;

  /// The color used for disabled dates, secondary text, and inactive icons.
  final Color? muted;

  /// The background color for unselected segments (Year/Month/Day) and grid items.
  final Color? tile;

  /// The background color for the currently active segment tab.
  final Color? activeTile;

  /// The color of the dialog's outer border.
  final Color? border;
}

/// Displays a compact, animated date picker with independent Year, Month, and Day views.
///
/// This function acts as a drop-in replacement for Flutter's built-in [showDatePicker].
/// It shares the exact same public parameter names, defaults, and return type.
///
/// The picker relies purely on the Flutter SDK and requires no platform-specific code.
///
/// Returns a [Future] that resolves to the selected [DateTime], or [null] if
/// the user cancels the dialog.
Future<DateTime?> showSegmentedDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? currentDate,
  DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
  SelectableDayPredicate? selectableDayPredicate,
  String? helpText,
  String? cancelText,
  String? confirmText,
  Locale? locale,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  TextDirection? textDirection,
  TransitionBuilder? builder,
  DatePickerMode initialDatePickerMode = DatePickerMode.day,
  String? errorFormatText,
  String? errorInvalidText,
  String? fieldHintText,
  String? fieldLabelText,
  TextInputType? keyboardType,
  Offset? anchorPoint,
  ValueChanged<DatePickerEntryMode>? onDatePickerModeChange,
  Icon? switchToInputEntryModeIcon,
  Icon? switchToCalendarEntryModeIcon,
  SegmentedPickerColors? pickerColors,
  CalendarDelegate<DateTime> calendarDelegate =
      const GregorianCalendarDelegate(),
}) {
  if (calendarDelegate is! GregorianCalendarDelegate) {
    // Fallback to native picker if a non-Gregorian calendar delegate is provided,
    // as this custom picker currently relies on Gregorian calculations.
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      currentDate: currentDate,
      initialEntryMode: initialEntryMode,
      selectableDayPredicate: selectableDayPredicate,
      helpText: helpText,
      cancelText: cancelText,
      confirmText: confirmText,
      locale: locale,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      textDirection: textDirection,
      builder: builder,
      initialDatePickerMode: initialDatePickerMode,
      errorFormatText: errorFormatText,
      errorInvalidText: errorInvalidText,
      fieldHintText: fieldHintText,
      fieldLabelText: fieldLabelText,
      keyboardType: keyboardType,
      anchorPoint: anchorPoint,
      onDatePickerModeChange: onDatePickerModeChange,
      switchToInputEntryModeIcon: switchToInputEntryModeIcon,
      switchToCalendarEntryModeIcon: switchToCalendarEntryModeIcon,
      calendarDelegate: calendarDelegate,
    );
  }

  final first = calendarDelegate.dateOnly(firstDate);
  final last = calendarDelegate.dateOnly(lastDate);
  final selected = initialDate == null
      ? null
      : calendarDelegate.dateOnly(initialDate);

  assert(!last.isBefore(first), 'lastDate must not precede firstDate.');
  assert(
    selected == null || !selected.isBefore(first),
    'initialDate must not precede firstDate.',
  );
  assert(
    selected == null || !selected.isAfter(last),
    'initialDate must not follow lastDate.',
  );
  assert(
    selectableDayPredicate == null ||
        selected == null ||
        selectableDayPredicate(selected),
    'initialDate must satisfy selectableDayPredicate.',
  );
  assert(debugCheckHasMaterialLocalizations(context));

  Widget content = _CompactDatePickerDialog(
    initialDate: selected,
    firstDate: first,
    lastDate: last,
    currentDate: currentDate == null
        ? null
        : calendarDelegate.dateOnly(currentDate),
    initialEntryMode: initialEntryMode,
    initialDatePickerMode: initialDatePickerMode,
    selectableDayPredicate: selectableDayPredicate,
    helpText: helpText,
    cancelText: cancelText,
    confirmText: confirmText,
    errorFormatText: errorFormatText,
    errorInvalidText: errorInvalidText,
    fieldHintText: fieldHintText,
    fieldLabelText: fieldLabelText,
    keyboardType: keyboardType,
    onDatePickerModeChange: onDatePickerModeChange,
    switchToInputEntryModeIcon: switchToInputEntryModeIcon,
    switchToCalendarEntryModeIcon: switchToCalendarEntryModeIcon,
    pickerColors: pickerColors,
    calendarDelegate: calendarDelegate,
  );

  final effectiveLocale = locale ?? DatePickerTheme.of(context).locale;
  if (effectiveLocale != null) {
    content = Localizations.override(
      context: context,
      locale: effectiveLocale,
      child: content,
    );
  }
  if (textDirection != null) {
    content = Directionality(textDirection: textDirection, child: content);
  }

  return showDialog<DateTime>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    builder: (dialogContext) =>
        builder == null ? content : builder(dialogContext, content),
  );
}

/// Identifies the currently active panel within the segmented picker.
enum _DatePanel { year, month, day }

/// Internal color resolution class.
///
/// Merges standard hardcoded fallbacks with any custom overrides provided
/// via [SegmentedPickerColors].
class _PickerColors {
  const _PickerColors._({
    required this.background,
    required this.header,
    required this.accent,
    required this.onAccent,
    required this.text,
    required this.muted,
    required this.tile,
    required this.activeTile,
    required this.border,
  });

  final Color background;
  final Color header;
  final Color accent;
  final Color onAccent;
  final Color text;
  final Color muted;
  final Color tile;
  final Color activeTile;
  final Color border;

  factory _PickerColors.from(
    BuildContext context,
    SegmentedPickerColors? custom,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _PickerColors._(
      background:
          custom?.background ??
          (isDark ? const Color(0xFF152226) : const Color(0xFFFFFFFF)),
      header:
          custom?.header ??
          (isDark ? const Color(0xFF1C3032) : const Color(0xFFF0F8F6)),
      accent:
          custom?.accent ??
          (isDark ? const Color(0xFF81DBCD) : const Color(0xFF08766E)),
      onAccent:
          custom?.onAccent ??
          (isDark ? const Color(0xFF102F2B) : const Color(0xFFFFFFFF)),
      text:
          custom?.text ??
          (isDark ? const Color(0xFFF0F7F5) : const Color(0xFF1F3037)),
      muted:
          custom?.muted ??
          (isDark ? const Color(0xFFAAC0BE) : const Color(0xFF697C82)),
      tile:
          custom?.tile ??
          (isDark ? const Color(0xFF233639) : const Color(0xFFF2F6F6)),
      activeTile:
          custom?.activeTile ??
          (isDark ? const Color(0xFF284744) : const Color(0xFFE0F1ED)),
      border:
          custom?.border ??
          (isDark ? const Color(0xFF354A4D) : const Color(0xFFDCE7E5)),
    );
  }
}

/// The internal stateful widget that constructs the layout, handles animations,
/// and manages user interactions for the segmented date picker.
class _CompactDatePickerDialog extends StatefulWidget {
  const _CompactDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.currentDate,
    required this.initialEntryMode,
    required this.initialDatePickerMode,
    required this.selectableDayPredicate,
    required this.helpText,
    required this.cancelText,
    required this.confirmText,
    required this.errorFormatText,
    required this.errorInvalidText,
    required this.fieldHintText,
    required this.fieldLabelText,
    required this.keyboardType,
    required this.onDatePickerModeChange,
    required this.switchToInputEntryModeIcon,
    required this.switchToCalendarEntryModeIcon,
    required this.pickerColors,
    required this.calendarDelegate,
  });

  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? currentDate;
  final DatePickerEntryMode initialEntryMode;
  final DatePickerMode initialDatePickerMode;
  final SelectableDayPredicate? selectableDayPredicate;
  final String? helpText;
  final String? cancelText;
  final String? confirmText;
  final String? errorFormatText;
  final String? errorInvalidText;
  final String? fieldHintText;
  final String? fieldLabelText;
  final TextInputType? keyboardType;
  final ValueChanged<DatePickerEntryMode>? onDatePickerModeChange;
  final Icon? switchToInputEntryModeIcon;
  final Icon? switchToCalendarEntryModeIcon;
  final SegmentedPickerColors? pickerColors;
  final CalendarDelegate<DateTime> calendarDelegate;

  @override
  State<_CompactDatePickerDialog> createState() =>
      _CompactDatePickerDialogState();
}

class _CompactDatePickerDialogState extends State<_CompactDatePickerDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime? _selected;
  late DateTime _visibleMonth;
  late _DatePanel _panel;
  late DatePickerEntryMode _entryMode;
  late final DateTime _today;

  bool get _isInput =>
      _entryMode == DatePickerEntryMode.input ||
      _entryMode == DatePickerEntryMode.inputOnly;
  bool get _canSwitch =>
      _entryMode != DatePickerEntryMode.inputOnly &&
      _entryMode != DatePickerEntryMode.calendarOnly;
  DateTime get _firstMonth =>
      DateTime(widget.firstDate.year, widget.firstDate.month);
  DateTime get _lastMonth =>
      DateTime(widget.lastDate.year, widget.lastDate.month);

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _today = widget.currentDate ?? DateUtils.dateOnly(DateTime.now());
    _entryMode = widget.initialEntryMode;
    _panel = widget.initialDatePickerMode == DatePickerMode.year
        ? _DatePanel.year
        : _DatePanel.day;
    final initial = widget.initialDate ?? _today;
    _visibleMonth = _clampMonth(DateTime(initial.year, initial.month));
  }

  /// Ensures the viewed month does not scroll beyond the permitted bounds.
  DateTime _clampMonth(DateTime value) {
    if (value.isBefore(_firstMonth)) return _firstMonth;
    if (value.isAfter(_lastMonth)) return _lastMonth;
    return value;
  }

  /// Evaluates whether a given date can be selected.
  bool _isEnabled(DateTime date) =>
      !date.isBefore(widget.firstDate) &&
      !date.isAfter(widget.lastDate) &&
      (widget.selectableDayPredicate?.call(date) ?? true);

  /// Locates the nearest selectable date if the previously selected day
  /// exceeds the boundaries of the newly chosen month (e.g., Feb 31st).
  DateTime? _closestValidDate(DateTime month, int preferredDay) {
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final targetDay = math.min(preferredDay, days);
    for (var distance = 0; distance < days; distance++) {
      final earlier = targetDay - distance;
      if (earlier >= 1) {
        final date = DateTime(month.year, month.month, earlier);
        if (_isEnabled(date)) return date;
      }
      if (distance > 0) {
        final later = targetDay + distance;
        if (later <= days) {
          final date = DateTime(month.year, month.month, later);
          if (_isEnabled(date)) return date;
        }
      }
    }
    return null;
  }

  /// Updates the currently visible month, adjusting selected day if necessary.
  void _changeMonth(
    DateTime requested, {
    _DatePanel? nextPanel,
    bool pickedFromGrid = false,
  }) {
    final month = _clampMonth(DateTime(requested.year, requested.month));
    final adjusted = pickedFromGrid && _selected != null
        ? _closestValidDate(month, _selected!.day)
        : _selected;

    setState(() {
      _visibleMonth = month;
      if (pickedFromGrid) _selected = adjusted;
    });

    if (nextPanel != null) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _panel = nextPanel);
      });
    }
  }

  /// Toggles between grid (calendar) and manual input mode.
  void _switchEntryMode() {
    final next = _isInput
        ? DatePickerEntryMode.calendar
        : DatePickerEntryMode.input;
    FocusScope.of(context).unfocus();
    setState(() => _entryMode = next);
    widget.onDatePickerModeChange?.call(next);
  }

  /// Submits the final selected date.
  void _confirm() {
    if (_isInput) {
      final form = _formKey.currentState;
      if (form == null || !form.validate()) return;
      form.save();
    }
    if (_selected != null && _isEnabled(_selected!)) {
      Navigator.of(context).pop(_selected);
    }
  }

  /// Formats the month string cleanly based on the provided locale.
  String _monthName(DateTime date, MaterialLocalizations l10n) {
    final monthYear = l10n.formatMonthYear(date);
    final year = l10n.formatYear(date);
    final month = monthYear
        .replaceFirst(year, '')
        .trim()
        .replaceAll(RegExp(r'^[,./\-\s]+|[,./\-\s]+$'), '');
    return month.isEmpty ? monthYear : month;
  }

  @override
  Widget build(BuildContext context) {
    final p = _PickerColors.from(context, widget.pickerColors);
    final l10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // Calculates available vertical space to prevent keyboard overflow issues in input mode.
    final available =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom -
        MediaQuery.paddingOf(context).vertical -
        24;

    final height = math.max(0.0, math.min(_isInput ? 228.0 : 480.0, available));
    final tight = height < 420;

    // Adjust maximum width to prevent overflow on very narrow devices (e.g., older SE devices).
    final safeWidth = math.min(374.0, MediaQuery.sizeOf(context).width - 32);

    final animation = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 170);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      clipBehavior: Clip.antiAlias,
      backgroundColor: p.background,
      elevation: 12,
      shadowColor: Colors.black.withAlpha(36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: p.border, width: 0.7),
      ),
      child: SizedBox(
        width: safeWidth,
        height: height,
        child: Column(
          children: [
            _buildHeader(p, l10n, theme, tight, animation),
            if (!_isInput) _buildSegments(p, l10n, tight, animation),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, tight ? 2 : 5, 14, 0),
                child: _isInput
                    ? _buildInput()
                    : AnimatedSwitcher(
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutQuart,
                        switchOutCurve: Curves.easeInQuad,
                        transitionBuilder: (child, anim) {
                          final scale = Tween<double>(
                            begin: 0.92,
                            end: 1.0,
                          ).animate(anim);
                          final slide = Tween<Offset>(
                            begin: const Offset(0, 0.04),
                            end: Offset.zero,
                          ).animate(anim);

                          return RepaintBoundary(
                            child: FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: slide,
                                child: ScaleTransition(
                                  scale: scale,
                                  child: child,
                                ),
                              ),
                            ),
                          );
                        },
                        layoutBuilder: (current, previous) => Stack(
                          fit: StackFit.expand,
                          children: [...previous, if (current != null) current],
                        ),
                        child: KeyedSubtree(
                          key: ValueKey((
                            _panel,
                            _panel == _DatePanel.day ? _visibleMonth.year : 0,
                            _panel == _DatePanel.day ? _visibleMonth.month : 0,
                          )),
                          child: switch (_panel) {
                            _DatePanel.year => _buildYears(p, animation),
                            _DatePanel.month => _buildMonths(
                              p,
                              l10n,
                              animation,
                            ),
                            _DatePanel.day => _buildDays(
                              p,
                              l10n,
                              animation,
                              tight,
                            ),
                          },
                        ),
                      ),
              ),
            ),
            _buildFooter(p, l10n, tight),
          ],
        ),
      ),
    );
  }

  /// Builds the top header containing the selected date and mode switch toggle.
  Widget _buildHeader(
    _PickerColors p,
    MaterialLocalizations l10n,
    ThemeData theme,
    bool tight,
    Duration animation,
  ) {
    return Container(
      color: p.header,
      padding: EdgeInsets.fromLTRB(18, tight ? 9 : 12, 12, tight ? 9 : 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: p.activeTile,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: p.accent,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.helpText ?? l10n.datePickerHelpText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: p.muted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: animation,
                  child: Text(
                    _selected == null
                        ? l10n.unspecifiedDate
                        : l10n.formatMediumDate(_selected!),
                    key: ValueKey(_selected),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: p.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_canSwitch)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: _isInput
                  ? l10n.calendarModeButtonLabel
                  : l10n.inputDateModeButtonLabel,
              onPressed: _switchEntryMode,
              color: p.accent,
              icon: _isInput
                  ? (widget.switchToCalendarEntryModeIcon ??
                        const Icon(Icons.calendar_month_rounded))
                  : (widget.switchToInputEntryModeIcon ??
                        const Icon(Icons.edit_calendar_outlined)),
            ),
        ],
      ),
    );
  }

  /// Builds the tabbed navigation for switching between Year, Month, and Day views.
  Widget _buildSegments(
    _PickerColors p,
    MaterialLocalizations l10n,
    bool tight,
    Duration animation,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14, tight ? 7 : 10, 14, 0),
      child: Row(
        children: [
          _segment(
            p,
            'Year',
            l10n.formatYear(_visibleMonth),
            _DatePanel.year,
            animation,
            tight,
          ),
          const SizedBox(width: 6),
          _segment(
            p,
            'Month',
            _monthName(_visibleMonth, l10n),
            _DatePanel.month,
            animation,
            tight,
          ),
          const SizedBox(width: 6),
          _segment(
            p,
            'Day',
            _selected?.day.toString() ?? '—',
            _DatePanel.day,
            animation,
            tight,
          ),
        ],
      ),
    );
  }

  /// Individual button widget for the segmentation tabs.
  Widget _segment(
    _PickerColors p,
    String label,
    String value,
    _DatePanel target,
    Duration animation,
    bool tight,
  ) {
    final active = _panel == target;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: '$label: $value',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: active ? null : () => setState(() => _panel = target),
            child: AnimatedContainer(
              duration: animation,
              curve: Curves.easeOutCubic,
              height: tight ? 48 : 53,
              decoration: BoxDecoration(
                color: active ? p.activeTile : p.tile,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: active ? p.accent.withAlpha(115) : Colors.transparent,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w800,
                      color: active ? p.accent : p.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: active ? p.accent : p.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the grid layout for selecting a specific year.
  Widget _buildYears(_PickerColors p, Duration animation) {
    final years = widget.lastDate.year - widget.firstDate.year + 1;
    final initialRow = (_visibleMonth.year - widget.firstDate.year) ~/ 3;
    final scrollOffset = math.max(0.0, initialRow * 56.0 - 80.0);

    return GridView.builder(
      controller: ScrollController(initialScrollOffset: scrollOffset),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: years,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 48,
      ),
      itemBuilder: (context, index) {
        final year = widget.firstDate.year + index;
        final active = year == _visibleMonth.year;

        return Semantics(
          button: true,
          selected: active,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _changeMonth(
                DateTime(year, _visibleMonth.month),
                nextPanel: _DatePanel.month,
                pickedFromGrid: true,
              ),
              child: TweenAnimationBuilder<double>(
                key: ValueKey(active ? 'selected_year' : 'unselected_year'),
                tween: Tween<double>(begin: active ? 0.75 : 1.0, end: 1.0),
                duration: animation.inMilliseconds == 0
                    ? Duration.zero
                    : const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: AnimatedContainer(
                  duration: animation,
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? p.accent : p.tile,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$year',
                    style: TextStyle(
                      color: active ? p.onAccent : p.text,
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the grid layout for selecting a specific month within the current year.
  Widget _buildMonths(
    _PickerColors p,
    MaterialLocalizations l10n,
    Duration animation,
  ) {
    return LayoutBuilder(
      builder: (context, size) => GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: 12,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          mainAxisExtent: math.max(1.0, (size.maxHeight - 24) / 4),
        ),
        itemBuilder: (context, index) {
          final month = DateTime(_visibleMonth.year, index + 1);
          final enabled =
              !month.isBefore(_firstMonth) && !month.isAfter(_lastMonth);
          final active = month.month == _visibleMonth.month;

          return Semantics(
            button: true,
            selected: active,
            enabled: enabled,
            label: _monthName(month, l10n),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: enabled
                    ? () => _changeMonth(
                        month,
                        nextPanel: _DatePanel.day,
                        pickedFromGrid: true,
                      )
                    : null,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(active ? 'selected_month' : 'unselected_month'),
                  tween: Tween<double>(begin: active ? 0.75 : 1.0, end: 1.0),
                  duration: animation.inMilliseconds == 0
                      ? Duration.zero
                      : const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: AnimatedContainer(
                    duration: animation,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? p.accent : p.tile,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _monthName(month, l10n),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: !enabled
                            ? p.muted.withAlpha(102)
                            : active
                            ? p.onAccent
                            : p.text,
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the standard calendar view grid for selecting a specific day.
  Widget _buildDays(
    _PickerColors p,
    MaterialLocalizations l10n,
    Duration animation,
    bool tight,
  ) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final offset = DateUtils.firstDayOffset(
      _visibleMonth.year,
      _visibleMonth.month,
      l10n,
    );
    final daysInMonth = DateUtils.getDaysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    final before = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    final after = DateTime(_visibleMonth.year, _visibleMonth.month + 1);

    return Column(
      children: [
        SizedBox(
          height: tight ? 34 : 38,
          child: Row(
            children: [
              _monthArrow(
                p,
                rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                l10n.previousMonthTooltip,
                before.isBefore(_firstMonth)
                    ? null
                    : () => _changeMonth(before),
              ),
              Expanded(
                child: Text(
                  l10n.formatMonthYear(_visibleMonth),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: p.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _monthArrow(
                p,
                rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                l10n.nextMonthTooltip,
                after.isAfter(_lastMonth) ? null : () => _changeMonth(after),
              ),
            ],
          ),
        ),
        SizedBox(
          height: tight ? 20 : 24,
          child: Row(
            children: List.generate(7, (index) {
              final weekday = (l10n.firstDayOfWeekIndex + index) % 7;
              return Expanded(
                child: Center(
                  child: Text(
                    l10n.narrowWeekdays[weekday],
                    style: TextStyle(
                      color: p.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: LayoutBuilder(
            builder: (context, size) => GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: 42,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
                mainAxisExtent: math.max(1.0, (size.maxHeight - 10) / 6),
              ),
              itemBuilder: (context, index) {
                final day = index - offset + 1;
                if (day < 1 || day > daysInMonth) {
                  return const SizedBox.shrink();
                }
                final date = DateTime(
                  _visibleMonth.year,
                  _visibleMonth.month,
                  day,
                );
                final enabled = _isEnabled(date);
                final selected = DateUtils.isSameDay(_selected, date);
                final today = DateUtils.isSameDay(_today, date);

                return Semantics(
                  label: l10n.formatFullDate(date),
                  button: true,
                  selected: selected,
                  enabled: enabled,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(11),
                      onTap: enabled
                          ? () => setState(() => _selected = date)
                          : null,
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(
                          selected ? 'selected_day' : 'unselected_day',
                        ),
                        tween: Tween<double>(
                          begin: selected ? 0.75 : 1.0,
                          end: 1.0,
                        ),
                        duration: animation.inMilliseconds == 0
                            ? Duration.zero
                            : const Duration(milliseconds: 500),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: AnimatedContainer(
                          duration: animation,
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? p.accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: today && !selected
                                  ? p.accent
                                  : Colors.transparent,
                              width: 1.1,
                            ),
                          ),
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: !enabled
                                  ? p.muted.withAlpha(92)
                                  : selected
                                  ? p.onAccent
                                  : p.text,
                              fontSize: tight ? 12 : 13,
                              fontWeight: selected || today
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Renders a navigational arrow for traversing months.
  Widget _monthArrow(
    _PickerColors p,
    IconData icon,
    String tooltip,
    VoidCallback? onPressed,
  ) {
    return SizedBox(
      width: 38,
      height: 38,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        color: p.text,
        disabledColor: p.muted.withAlpha(89),
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
      ),
    );
  }

  /// Builds the manual input text field form when the picker is toggled into text-entry mode.
  Widget _buildInput() {
    return Center(
      child: Form(
        key: _formKey,
        child: InputDatePickerFormField(
          initialDate: _selected,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          onDateSaved: (date) => _selected = date,
          onDateSubmitted: (date) {
            if (_isEnabled(date)) Navigator.of(context).pop(date);
          },
          selectableDayPredicate: widget.selectableDayPredicate,
          errorFormatText: widget.errorFormatText,
          errorInvalidText: widget.errorInvalidText,
          fieldHintText: widget.fieldHintText,
          fieldLabelText: widget.fieldLabelText,
          keyboardType: widget.keyboardType,
          autofocus: true,
          calendarDelegate: widget.calendarDelegate,
        ),
      ),
    );
  }

  /// Action buttons at the bottom of the dialog (Cancel/Ok).
  Widget _buildFooter(_PickerColors p, MaterialLocalizations l10n, bool tight) {
    return Container(
      padding: EdgeInsets.fromLTRB(14, tight ? 3 : 7, 14, tight ? 8 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: p.muted,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            ),
            child: Text(widget.cancelText ?? l10n.cancelButtonLabel),
          ),
          const SizedBox(width: 5),
          FilledButton(
            onPressed: _isInput || _selected != null ? _confirm : null,
            style: FilledButton.styleFrom(
              backgroundColor: p.accent,
              foregroundColor: p.onAccent,
              disabledBackgroundColor: p.tile,
              disabledForegroundColor: p.muted,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              minimumSize: const Size(76, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: Text(
              widget.confirmText ?? l10n.okButtonLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
