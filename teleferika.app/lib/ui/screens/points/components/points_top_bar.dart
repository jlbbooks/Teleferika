import 'package:flutter/material.dart';
import 'package:teleferika/l10n/app_localizations.dart';

class PointsTopBar extends StatelessWidget {
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const PointsTopBar({
    super.key,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSelectionMode) {
      return const SizedBox.shrink();
    }

    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: s?.buttonCancel ?? 'Cancel',
            onPressed: onCancel,
          ),
          Text(s?.selected_count(selectedCount) ?? '$selectedCount selected'),
          TextButton.icon(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            label: Text(
              s?.buttonDelete ?? 'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onPressed: selectedCount > 0 ? onDelete : null,
          ),
        ],
      ),
    );
  }
}
