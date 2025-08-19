import 'package:flutter/material.dart';

class TableToolbar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final List<Widget> actions;
  final String hint;
  final double spacing;

  const TableToolbar({
    super.key,
    required this.searchCtrl,
    required this.onSearchChanged,
    this.actions = const [],
    this.hint = 'Szukaj...',
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 12,
      spacing: spacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: searchCtrl,
            decoration: InputDecoration(
              labelText: hint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchCtrl.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
            ),
            onChanged: onSearchChanged,
          ),
        ),
        ...actions,
      ],
    );
  }
}
