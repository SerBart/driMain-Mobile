import 'package:flutter/material.dart';

/// Ulepszona wersja DataTable z:
/// - opcjonalnym header
/// - horizontal scroll + minWidth
/// - prostą obsługą sortowania przekazaną na poziomie tabeli:
///   podajesz onSort / sortColumnIndex / sortAscending i (domyślnie)
///   wszystkie kolumny stają się sortowalne, chyba że:
///   - kolumna ma już własny onSort (zostawiamy ją),
///   - podasz [sortableColumns] (zbiór indeksów które mają być sortowalne).
class DataTablePro extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final Widget? header;
  final double? minWidth;
  final EdgeInsetsGeometry padding;

  /// Indeks aktualnie sortowanej kolumny (przekazywane do DataTable).
  final int? sortColumnIndex;

  /// Kierunek sortowania (przekazywany do DataTable).
  final bool sortAscending;

  /// Callback globalny – jeśli ustawiony, kolumny (bez własnego onSort)
  /// otrzymają onSort wywołujący ten callback.
  final void Function(int columnIndex, bool ascending)? onSort;

  /// Jeśli chcesz ograniczyć które kolumny są sortowalne przy globalnym onSort.
  /// Jeśli null i onSort != null → wszystkie.
  final Set<int>? sortableColumns;

  const DataTablePro({
    super.key,
    required this.columns,
    required this.rows,
    this.header,
    this.minWidth,
    this.padding = const EdgeInsets.all(12),
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.sortableColumns,
  });

  List<DataColumn> _buildColumns() {
    if (onSort == null) {
      return columns;
    }
    return List<DataColumn>.generate(columns.length, (i) {
      final original = columns[i];

      // Jeśli już ma własne onSort albo ta kolumna nie jest w zbiorze sortowalnych – zostawiamy.
      final isAllowed = sortableColumns == null || sortableColumns!.contains(i);
      if (original.onSort != null || !isAllowed) {
        return original;
      }

      return DataColumn(
        label: original.label,
        tooltip: original.tooltip,
        numeric: original.numeric,
        onSort: (col, asc) => onSort!(col, asc),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColumns = _buildColumns();

    final table = DataTable(
      columns: effectiveColumns,
      rows: rows,
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      headingTextStyle: Theme.of(context)
          .textTheme
          .labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
      dataRowColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.hovered)) {
            return Theme.of(context).colorScheme.primary.withOpacity(.04);
          }
          return null;
        },
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: header!,
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth ?? 900),
            child: Padding(
              padding: padding,
              child: table,
            ),
          ),
        ),
      ],
    );
  }
}