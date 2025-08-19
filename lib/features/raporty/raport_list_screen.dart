import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/models/raport.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/section_header.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/table/data_table_pro.dart';
import '../../widgets/dialogs.dart';

class RaportyListScreen extends ConsumerStatefulWidget {
  const RaportyListScreen({super.key});

  @override
  ConsumerState<RaportyListScreen> createState() => _RaportyListScreenState();
}

class _RaportyListScreenState extends ConsumerState<RaportyListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _statusFilter = 'WSZYSTKIE';

  // Sort
  int _sortCol = 3; // domyślnie po dacie
  bool _asc = false;

  final _dateFmt = DateFormat('yyyy-MM-dd');
  final _timeFmt = DateFormat('HH:mm');

  static const _statusy = [
    'NOWY',
    'W TOKU',
    'OCZEKUJE',
    'ZAKOŃCZONY',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Raport> _filtered(List<Raport> all) {
    var list = List<Raport>.from(all);

    // Wyszukiwanie
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((r) {
        return r.typNaprawy.toLowerCase().contains(q) ||
            (r.maszyna?.nazwa.toLowerCase().contains(q) ?? false) ||
            r.status.toLowerCase().contains(q) ||
            r.id.toString() == q;
      }).toList();
    }

    // Filtr statusu
    if (_statusFilter != 'WSZYSTKIE') {
      list = list
          .where((r) => r.status.toUpperCase() == _statusFilter.toUpperCase())
          .toList();
    }

    // Sort
    list.sort((a, b) {
      int cmp;
      switch (_sortCol) {
        case 0: // ID
          cmp = a.id.compareTo(b.id);
          break;
        case 1: // Maszyna
          cmp = (a.maszyna?.nazwa ?? '').compareTo(b.maszyna?.nazwa ?? '');
          break;
        case 2: // Typ
          cmp = a.typNaprawy.compareTo(b.typNaprawy);
          break;
        case 3: // Data
          cmp = a.dataNaprawy.compareTo(b.dataNaprawy);
          break;
        case 4: // Status
          cmp = a.status.compareTo(b.status);
          break;
        case 5: // Czas (czasOd)
          cmp = a.czasOd.compareTo(b.czasOd);
          break;
        default:
          cmp = a.id.compareTo(b.id);
      }
      return _asc ? cmp : -cmp;
    });

    return list;
  }

  void _onSort(int index, bool asc) {
    setState(() {
      _sortCol = index;
      _asc = asc;
    });
  }

  Widget _statusChipFilter(String label) {
    final sel = _statusFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) => setState(() => _statusFilter = label),
      ),
    );
  }

  Future<void> _deleteRaport(Raport r) async {
    final ok = await showConfirmDialog(
      context,
      'Usuń raport #${r.id}',
      'Czy na pewno usunąć raport? Tej operacji nie można cofnąć (demo).',
    );
    if (ok == true) {
      ref.read(mockRepoProvider).deleteRaport(r.id);
      if (mounted) {
        setState(() {});
        showSuccessDialog(
            context, 'Usunięto', 'Raport #${r.id} został usunięty.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(mockRepoProvider);
    final raporty = _filtered(repo.getRaporty());

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Raporty'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/raport/nowy'),
        icon: const Icon(Icons.add),
        label: const Text('Nowy raport'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Raporty serwisowe',
            subtitle: 'Ewidencja interwencji / napraw / prac utrzymaniowych',
          ),
          AppCard(
            title: 'Filtrowanie',
            divided: true,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    labelText: 'Szukaj (maszyna / typ / status / ID)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _statusChipFilter('WSZYSTKIE'),
                      ..._statusy.map(_statusChipFilter),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppCard(
            title: 'Lista raportów',
            action: Text(
              '${raporty.length} rekordów',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            child: DataTablePro(
              columns: [
                DataColumn(
                  label: const Text('ID'),
                  numeric: true,
                  onSort: (i, asc) => _onSort(i, asc),
                ),
                DataColumn(
                  label: const Text('Maszyna'),
                  onSort: (i, asc) => _onSort(i, asc),
                ),
                DataColumn(
                  label: const Text('Typ'),
                  onSort: (i, asc) => _onSort(i, asc),
                ),
                DataColumn(
                  label: const Text('Data'),
                  onSort: (i, asc) => _onSort(i, asc),
                ),
                DataColumn(
                  label: const Text('Status'),
                  onSort: (i, asc) => _onSort(i, asc),
                ),
                DataColumn(
                  label: const Text('Czas (od-do)'),
                  onSort: (i, asc) => _onSort(i, asc),
                ),
                const DataColumn(label: Text('Akcje')),
              ],
              rows: raporty.map((r) {
                final d = _dateFmt.format(r.dataNaprawy);
                final czas =
                    '${_timeFmt.format(r.czasOd)} - ${_timeFmt.format(r.czasDo)}';
                return DataRow(
                  cells: [
                    DataCell(Text(r.id.toString())),
                    DataCell(Text(r.maszyna?.nazwa ?? '-')),
                    DataCell(Text(r.typNaprawy)),
                    DataCell(Text(d)),
                    DataCell(StatusChip(status: r.status, useGradient: true)),
                    DataCell(Text(czas)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edytuj',
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () =>
                                context.go('/raport/edytuj/${r.id}'),
                          ),
                          IconButton(
                            tooltip: 'Usuń',
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => _deleteRaport(r),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
