import 'package:flutter/material.dart';
import 'package:yomuyomu/Mangas/enums/reading_status.dart';

class FilterStatusDialog extends StatefulWidget {
  final Map<ReadingStatus, bool> filterStatus;
  final Function(List<ReadingStatus>) onFilterApplied;

  const FilterStatusDialog({required this.filterStatus, required this.onFilterApplied, super.key});

  @override
  FilterStatusDialogState createState() => FilterStatusDialogState();
}

class FilterStatusDialogState extends State<FilterStatusDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Filter By Status"),
      content: SingleChildScrollView(
        child: Column(
          children: ReadingStatus.values.map((status) {
            return CheckboxListTile(
              title: Text(status.name),
              value: widget.filterStatus[status],
              onChanged: (bool? value) {
                setState(() {
                  widget.filterStatus[status] = value!;
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            final selectedStatus = widget.filterStatus.entries.where((e) => e.value).map((e) => e.key).toList();
            widget.onFilterApplied(selectedStatus);
            Navigator.pop(context);
          },
          child: const Text("Accept"),
        ),
      ],
    );
  }
}

