import 'package:flutter/material.dart';

class DateRangeFilter extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;

  const DateRangeFilter({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filter by Date Range',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _selectDate(context, true),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      startDate != null
                          ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
                          : 'Start Date',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _selectDate(context, false),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      endDate != null
                          ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
                          : 'End Date',
                    ),
                  ),
                ),
              ],
            ),
            if (startDate != null || endDate != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  onStartDateChanged(null);
                  onEndDateChanged(null);
                },
                child: const Text('Clear Filter'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate ?? DateTime.now() : endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      if (isStartDate) {
        onStartDateChanged(picked);
      } else {
        onEndDateChanged(picked);
      }
    }
  }
} 