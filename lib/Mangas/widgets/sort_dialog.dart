import 'package:flutter/material.dart';

class SortDialog extends StatelessWidget {
  final Function(int) onSortSelected;

  const SortDialog({required this.onSortSelected, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: const Text("Alphabetically"),
          onTap: () => _applySort(context, 0),
        ),
        ListTile(
          title: const Text("Total Chapters"),
          onTap: () => _applySort(context, 1),
        ),
        ListTile(
          title: const Text("Rating"),
          onTap: () => _applySort(context, 2),
        ),
      ],
    );
  }

  void _applySort(BuildContext context, int sortType) {
    onSortSelected(sortType);
    Navigator.pop(context);
  }
}
