import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../models/subscription_provider.dart';
import '../models/subscription.dart';
import '../widgets/brand_icon.dart';
import '../widgets/press_scale.dart';
import '../widgets/page_transitions.dart';
import '../widgets/odometer_roll.dart';
import 'subscription_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SubscriptionProvider>();
    final bills = p.billsForMonth(_focusedMonth.year, _focusedMonth.month);
    final sym = CurrencyProvider.getSymbol(p.displayCurrency);
    final monthTotal = bills.fold<double>(0,
        (sum, s) => sum + s.convertedMonthlyAmount(p.displayCurrency));

    return Scaffold(
      appBar: AppBar(
        title: Text(_monthYear(_focusedMonth)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous month',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next month',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));
            },
          ),
        ],
      ),
      body: CustomScrollView(slivers: [
        // ── Month summary card ──
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(PingTheme.spaceLg),
            padding: const EdgeInsets.all(PingTheme.spaceXl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [PingTheme.primary.withValues(alpha: 0.08), PingTheme.primary.withValues(alpha: 0.03)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(PingTheme.radiusLg),
              border: Border.all(color: PingTheme.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_monthName(_focusedMonth),
                      style: TextStyle(
                        fontSize: PingTheme.textSmall,
                        color: PingTheme.subtleText(context),
                        fontWeight: FontWeight.w500,
                      )),
                  const SizedBox(height: 4),
                  OdometerRoll(
                    value: monthTotal,
                    prefix: sym,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: PingTheme.primary,
                    ),
                  ),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  OdometerRoll(
                    value: bills.length.toDouble(),
                    decimalPlaces: 0,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: PingTheme.primary,
                    ),
                  ),
                  Text('bills',
                      style: TextStyle(
                        fontSize: PingTheme.textSmall,
                        color: PingTheme.subtleText(context),
                      )),
                ]),
              ],
            ),
          ),
        ),

        // ── Calendar grid ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: PingTheme.spaceLg),
            child: _buildCalendarGrid(context, bills),
          ),
        ),

        // ── Bills list for month ──
        if (bills.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  PingTheme.spaceLg, PingTheme.spaceXl, PingTheme.spaceLg, PingTheme.spaceSm),
              child: Text('Bills this month',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700)),
            ),
          ),
          SliverList.builder(
            itemCount: bills.length,
            itemBuilder: (context, i) => _billTile(context, bills[i], sym),
          ),
        ] else ...[
          SliverToBoxAdapter(
            child: RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.all(PingTheme.space4Xl),
                child: Column(children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PingTheme.success.withValues(alpha: 0.08),
                    ),
                    child: Icon(Icons.event_available, size: 32, color: PingTheme.success),
                  ),
                  const SizedBox(height: PingTheme.spaceLg),
                  Text('No bills this month',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: PingTheme.textBody)),
                  const SizedBox(height: 4),
                  Text('You\'re in the clear 🎉',
                      style: TextStyle(
                          color: PingTheme.subtleText(context),
                          fontSize: PingTheme.textCaption)),
                ]),
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: PingTheme.space3Xl)),
      ]),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, List<Subscription> bills) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday; // Mon=1, Sun=7
    final today = DateTime.now();
    final isCurrentMonth = today.year == _focusedMonth.year && today.month == _focusedMonth.month;

    // Map day → bills on that day
    final dayBills = <int, List<Subscription>>{};
    for (final b in bills) {
      final day = b.nextBillingDate.day;
      dayBills.putIfAbsent(day, () => []).add(b);
    }

    const weekHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(PingTheme.spaceMd),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(PingTheme.radiusLg),
        border: Border.all(color: PingTheme.hairlineBorder(context)),
      ),
      child: Column(children: [
        // Weekday headers
        Row(children: weekHeaders.map((d) {
          return Expanded(child: Center(child: Padding(
            padding: const EdgeInsets.only(bottom: PingTheme.spaceSm),
            child: Text(d,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: PingTheme.subtleText(context),
                )),
          )));
        }).toList()),
        // Days
        ...List.generate(((startWeekday - 1 + daysInMonth) / 7).ceil(), (weekIndex) {
          return Row(children: List.generate(7, (dayIndex) {
            final dayNum = weekIndex * 7 + dayIndex - (startWeekday - 1) + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 44));
            }
            final hasBills = dayBills.containsKey(dayNum);
            final isToday = isCurrentMonth && dayNum == today.day;
            return Expanded(child: Container(
              height: 44,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isToday
                    ? PingTheme.primary.withValues(alpha: 0.12)
                    : hasBills
                        ? PingTheme.warning.withValues(alpha: 0.08)
                        : null,
                borderRadius: BorderRadius.circular(PingTheme.radiusSm),
                border: isToday
                    ? Border.all(color: PingTheme.primary, width: 1.5)
                    : null,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$dayNum',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
                      color: isToday ? PingTheme.primary : null,
                    )),
                if (hasBills)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: dayBills[dayNum]!.take(3).map((b) {
                      final color = b.themeColor ??
                          SubscriptionTheme.categoryColors[b.category] ??
                          PingTheme.primary;
                      return Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
              ]),
            ));
          }));
        }),
      ]),
    );
  }

  Widget _billTile(BuildContext context, Subscription s, String sym) {
    final themeColor = s.themeColor ??
        SubscriptionTheme.categoryColors[s.category] ??
        PingTheme.primary;
    return Container(
      margin: const EdgeInsets.fromLTRB(
          PingTheme.spaceLg, 0, PingTheme.spaceLg, PingTheme.spaceSm),
      padding: const EdgeInsets.symmetric(
          horizontal: PingTheme.spaceMd, vertical: PingTheme.spaceSm + 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(PingTheme.radiusMd),
        border: Border.all(color: PingTheme.hairlineBorder(context)),
      ),
      child: PressScale(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(context, SlideFadeRoute(page: SubscriptionDetailScreen(id: s.id)));
        },
        child: Row(children: [
          Hero(
            tag: 'brand_${s.id}',
            child: BrandIcon(name: s.name, fallbackColor: themeColor, size: 42),
          ),
          const SizedBox(width: PingTheme.spaceMd),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.name,
                  style: const TextStyle(
                      fontSize: PingTheme.textBody, fontWeight: FontWeight.w600)),
              Text('${s.currencySymbol}${s.amount.toStringAsFixed(2)} · ${s.billingCycle}',
                  style: TextStyle(
                      fontSize: PingTheme.textCaption,
                      color: PingTheme.subtleText(context))),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: PingTheme.spaceSm, vertical: 4),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(PingTheme.radiusSm),
            ),
            child: Text(
              '${s.nextBillingDate.day} ${_monthName(s.nextBillingDate)}',
              style: TextStyle(
                fontSize: PingTheme.textSmall,
                fontWeight: FontWeight.w600,
                color: themeColor,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  String _monthYear(DateTime d) {
    const months = ['January','February','March','April','May','June','July',
        'August','September','October','November','December'];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _monthName(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[d.month - 1];
  }
}
