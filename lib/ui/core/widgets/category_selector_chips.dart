import 'package:flutter/material.dart';

/// Reusable single-select chip group compatible across all Flutter 3.x releases.
class CategorySelectorChips<T> extends StatelessWidget {
  const CategorySelectorChips({
    super.key,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: values
          .map(
            (item) => ChoiceChip(
              label: Text(labelBuilder(item)),
              selected: item == selected,
              onSelected: (isSelected) {
                if (isSelected) onSelected(item);
              },
            ),
          )
          .toList(),
    );
  }
}
