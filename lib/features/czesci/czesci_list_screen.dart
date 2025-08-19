import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/models/part.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/section_header.dart';
import '../../widgets/app_card.dart';
import '../../widgets/table/data_table_pro.dart';
import '../../widgets/dialogs.dart';

class CzesciListScreen extends ConsumerStatefulWidget {
  const CzesciListScreen({super.key});

  @override
  ConsumerState<CzesciListScreen> createState() => _CzesciListScreenState();
}

class _CzesciListScreenState extends ConsumerState<CzesciListScreen> {
  final _searchCtrl = TextEditingController();

  // Dodawanie
  final _nazwaCtrl = TextEditingController();
  final _kodCtrl = TextEditingController();
  final _iloscCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _jednCtrl = TextEditingController(text: 'szt');
  final _katCtrl = TextEditingController();

  String _query = '';
  String _filter = 'WSZYSTKIE'; // WSZYSTKIE / PONIZEJ_MIN / KATEGORIA:<nazwa>
  int _sortCol = 0;
  bool _asc = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nazwaCtrl.dispose();
    _kodCtrl.dispose();
    _iloscCtrl.dispose();
    _minCtrl.dispose();
    _jednCtrl.dispose();
    _katCtrl.dispose();
    super.dispose();
  }

  Set<String> _kategorie(List<Part> parts) =>
      parts.map((p) => p.kategoria).whereType<String>().toSet()
        ..removeWhere((e) => e.trim().isEmpty);

  List<Part> _filtered(List<Part> source) {
    var list = List<Part>.from(source);

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((p) {
        return p.nazwa.toLowerCase().contains(q) ||
            p.kod.toLowerCase().contains(q) ||
            (p.kategoria?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    if (_filter == 'PONIZEJ_MIN') {
      list = list.where((p) => p.belowMin).toList();
    } else if (_filter.startsWith('KATEGORIA:')) {
      final cat = _filter.split(':').skip(1).join(':');
      list = list
          .where((p) => (p.kategoria ?? '').toLowerCase() == cat.toLowerCase())
          .toList();
    }

    list.sort((a, b) {
      int cmp;
      switch (_sortCol) {
        case 0:
          cmp = a.nazwa.compareTo(b.nazwa);
          break;
        case 1:
          cmp = a.kod.compareTo(b.kod);
          break;
        case 2:
          cmp = (a.kategoria ?? '').compareTo(b.kategoria ?? '');
          break;
        case 3:
          cmp = a.iloscMagazyn.compareTo(b.iloscMagazyn);
          break;
        case 4:
          cmp = a.minIlosc.compareTo(b.minIlosc);
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

  Widget _filterChip(String label, {String? value}) {
    final val = value ?? label;
    final sel = _filter == val;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) => setState(() => _filter = val),
      ),
    );
  }

  Future<void> _deletePart(Part p) async {
    final ok = await showConfirmDialog(
      context,
      'Usuń część',
      'Czy na pewno usunąć "${p.nazwa}"?',
    );
    if (ok == true) {
      ref.read(mockRepoProvider).deletePart(p.id);
      if (mounted) {
        setState(() {});
        showSuccessDialog(context, 'Usunięto', 'Część została usunięta.');
      }
    }
  }

  void _adjustQty(Part p, int delta) {
    final repo = ref.read(mockRepoProvider);
    try {
      repo.adjustPartQuantity(p.id, delta);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd: $e')),
      );
    }
  }

  void _editPartDialog(Part part) {
    final nazwa = TextEditingController(text: part.nazwa);
    final kod = TextEditingController(text: part.kod);
    final min = TextEditingController(text: part.minIlosc.toString());
    final jedn = TextEditingController(text: part.jednostka);
    final kat = TextEditingController(text: part.kategoria ?? '');

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (ctx, setLocal) => SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text('Edytuj #${part.id}',
                            style: Theme.of(context).textTheme.titleLarge),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nazwa,
                      decoration: const InputDecoration(labelText: 'Nazwa'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: kod,
                      decoration: const InputDecoration(labelText: 'Kod'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: kat,
                      decoration:
                          const InputDecoration(labelText: 'Kategoria / typ'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: min,
                      decoration:
                          const InputDecoration(labelText: 'Min. ilość'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: jedn,
                      decoration: const InputDecoration(labelText: 'Jednostka'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Anuluj'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            final repo = ref.read(mockRepoProvider);
                            repo.updatePart(part.copyWith(
                              nazwa: nazwa.text.trim(),
                              kod: kod.text.trim(),
                              kategoria: kat.text.trim().isEmpty
                                  ? null
                                  : kat.text.trim(),
                              minIlosc: int.tryParse(min.text.trim()) ??
                                  part.minIlosc,
                              jednostka: jedn.text.trim().isEmpty
                                  ? part.jednostka
                                  : jedn.text.trim(),
                            ));
                            Navigator.pop(context);
                            setState(() {});
                          },
                          child: const Text('Zapisz'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddPartDialog() {
    _nazwaCtrl.clear();
    _kodCtrl.clear();
    _iloscCtrl.clear();
    _minCtrl.clear();
    _katCtrl.clear();
    _jednCtrl.text = 'szt';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (ctx, setLocal) => SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text('Dodaj część',
                            style: Theme.of(context).textTheme.titleLarge),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nazwaCtrl,
                      decoration: const InputDecoration(labelText: 'Nazwa'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _kodCtrl,
                      decoration: const InputDecoration(labelText: 'Kod'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _katCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Kategoria / typ'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _iloscCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Ilość początkowa'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _minCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Min. ilość'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _jednCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Jednostka'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Anuluj'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (_nazwaCtrl.text.trim().isEmpty ||
                                _kodCtrl.text.trim().isEmpty) return;
                            final repo = ref.read(mockRepoProvider);
                            repo.addPart(
                              nazwa: _nazwaCtrl.text.trim(),
                              kod: _kodCtrl.text.trim(),
                              ilosc: int.tryParse(_iloscCtrl.text) ?? 0,
                              minIlosc: int.tryParse(_minCtrl.text) ?? 0,
                              jednostka: _jednCtrl.text.trim().isEmpty
                                  ? 'szt'
                                  : _jednCtrl.text.trim(),
                              kategoria: _katCtrl.text.trim().isEmpty
                                  ? null
                                  : _katCtrl.text.trim(),
                            );
                            Navigator.pop(context);
                            setState(() {});
                          },
                          label: const Text('Dodaj'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(mockRepoProvider);
    final all = repo.getParts();
    final cats = _kategorie(all);
    final list = _filtered(all);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Części'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPartDialog,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj część'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Części zamienne',
            subtitle: 'Magazyn części / materiały eksploatacyjne',
          ),
          AppCard(
            title: 'Filtrowanie',
            divided: true,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    labelText: 'Szukaj (nazwa / kod / kategoria)',
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
                      _filterChip('WSZYSTKIE'),
                      _filterChip('Poniżej min', value: 'PONIZEJ_MIN'),
                      for (final c in cats)
                        _filterChip(c, value: 'KATEGORIA:$c'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppCard(
            title: 'Lista części',
            action: Text(
              '${list.length} rekordów',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            child: DataTablePro(
              columns: [
                DataColumn(
                  label: const Text('Nazwa'),
                  onSort: (i, asc) => _onSort(i, asc),
                ),
                DataColumn(
                  label: const Text('Kod'),
                  onSort: (i, asc) => _onSort(i, asc),
                ),
                DataColumn(
                  label: const Text('Kategoria'),
                  onSort: (i, asc) => _onSort(i, asc),
                ),
                DataColumn(
                  numeric: true,
                  label: const Text('Stan'),
                  onSort: (i, asc) => _onSort(i, asc),
                ),
                DataColumn(
                  numeric: true,
                  label: const Text('Min'),
                  onSort: (i, asc) => _onSort(i, asc),
                ),
                const DataColumn(label: Text('Jedn.')),
                const DataColumn(label: Text('Akcje')),
              ],
              rows: list.map((p) {
                final dangerBg = p.belowMin
                    ? Theme.of(context).colorScheme.error.withOpacity(.08)
                    : null;
                return DataRow(
                  color: dangerBg != null
                      ? WidgetStatePropertyAll(dangerBg)
                      : null,
                  cells: [
                    DataCell(Text(p.nazwa)),
                    DataCell(Text(p.kod)),
                    DataCell(Text(p.kategoria ?? '-')),
                    DataCell(Text(p.iloscMagazyn.toString())),
                    DataCell(Text(p.minIlosc.toString())),
                    DataCell(Text(p.jednostka)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Zwiększ',
                            icon: const Icon(Icons.add_circle_outline,
                                color: Colors.green),
                            onPressed: () => _adjustQty(p, 1),
                          ),
                          IconButton(
                            tooltip: 'Zmniejsz',
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.orange),
                            onPressed: () => _adjustQty(p, -1),
                          ),
                          IconButton(
                            tooltip: 'Edytuj',
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editPartDialog(p),
                          ),
                          IconButton(
                            tooltip: 'Usuń',
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deletePart(p),
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
