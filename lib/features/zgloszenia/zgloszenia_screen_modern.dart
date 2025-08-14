import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/models/zgloszenie.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/table/data_table_pro.dart';
import '../../widgets/photo_picker_field.dart';

class ZgloszeniaScreenModern extends ConsumerStatefulWidget {
  const ZgloszeniaScreenModern({super.key});

  @override
  ConsumerState<ZgloszeniaScreenModern> createState() =>
      _ZgloszeniaScreenModernState();
}

class _ZgloszeniaScreenModernState
    extends ConsumerState<ZgloszeniaScreenModern> {
  final _formKey = GlobalKey<FormState>();
  final _imieCtrl = TextEditingController();
  final _nazCtrl = TextEditingController();
  final _opisCtrl = TextEditingController();
  String _status = 'NOWE';
  String _typSelected = 'Usterka';
  String _query = '';
  String _statusFilter = 'WSZYSTKIE';
  final _search = TextEditingController();
  final _dtf = DateFormat('yyyy-MM-dd HH:mm');
  int _sortCol = 1;
  bool _asc = false;
  String? _photoBase64; // NOWE – zdjęcie dla formularza dodawania

  static const types = ['Usterka', 'Awaria', 'Przezbrojenie'];
  static const statusy = ['NOWE', 'W TOKU', 'WERYFIKACJA', 'ZAMKNIĘTE'];

  @override
  void dispose() {
    _imieCtrl.dispose();
    _nazCtrl.dispose();
    _opisCtrl.dispose();
    _search.dispose();
    super.dispose();
  }

  List<Zgloszenie> _filtered(List<Zgloszenie> all) {
    var list = List<Zgloszenie>.from(all);

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((z) {
        return z.typ.toLowerCase().contains(q) ||
            z.opis.toLowerCase().contains(q) ||
            z.imie.toLowerCase().contains(q) ||
            z.nazwisko.toLowerCase().contains(q) ||
            z.status.toLowerCase().contains(q) ||
            z.id.toString() == q;
      }).toList();
    }

    if (_statusFilter != 'WSZYSTKIE') {
      list = list
          .where((z) => z.status.toUpperCase() == _statusFilter.toUpperCase())
          .toList();
    }

    final sorted = List<Zgloszenie>.from(list);
    sorted.sort((a, b) {
      int cmp;
      switch (_sortCol) {
        case 0:
          cmp = a.id.compareTo(b.id);
          break;
        case 1:
          cmp = a.dataGodzina.compareTo(b.dataGodzina);
          break;
        case 2:
          cmp = a.typ.compareTo(b.typ);
          break;
        case 3:
          cmp = ('${a.imie} ${a.nazwisko}').compareTo('${b.imie} ${b.nazwisko}');
          break;
        case 4:
          cmp = a.status.compareTo(b.status);
          break;
        case 5: // sort po lastUpdated (jeśli dodasz kolumnę)
          cmp = a.lastUpdated.compareTo(b.lastUpdated);
          break;
        default:
          cmp = b.id.compareTo(a.id);
      }
      return _asc ? cmp : -cmp;
    });
    return sorted;
  }

  void _onSort(int i, bool asc) {
    setState(() {
      _sortCol = i;
      _asc = asc;
    });
  }

  void _add() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(mockRepoProvider).addZgloszenie(
          Zgloszenie(
            id: 0,
            imie: _imieCtrl.text.trim(),
            nazwisko: _nazCtrl.text.trim(),
            typ: _typSelected,
            dataGodzina: DateTime.now(),
            opis: _opisCtrl.text.trim(),
            status: _status,
            photoBase64: _photoBase64,
          ),
        );
    _imieCtrl.clear();
    _nazCtrl.clear();
    _opisCtrl.clear();
    _status = 'NOWE';
    _typSelected = 'Usterka';
    _photoBase64 = null;
    setState(() {});
  }

  void _showPhoto(String b64) {
    late final Image img;
    try {
      img = Image.memory(base64Decode(b64), fit: BoxFit.contain);
    } catch (_) {
      return;
    }
    showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(16),
          child: InteractiveViewer(child: img),
        ),
      ),
    );
  }

  void _editDialog(Zgloszenie z) {
    final imie = TextEditingController(text: z.imie);
    final nazw = TextEditingController(text: z.nazwisko);
    final opis = TextEditingController(text: z.opis);
    String typ = types.contains(z.typ) ? z.typ : types.first;
    String status = z.status;
    String? localPhoto = z.photoBase64;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (ctx, setLocal) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text('Edytuj #${z.id}',
                          style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: imie,
                          decoration:
                              const InputDecoration(labelText: 'Imię'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: nazw,
                          decoration:
                              const InputDecoration(labelText: 'Nazwisko'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: typ,
                    decoration: const InputDecoration(labelText: 'Typ'),
                    items: types
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t),
                            ))
                        .toList(),
                    onChanged: (v) => setLocal(() => typ = v ?? typ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: statusy
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s),
                            ))
                        .toList(),
                    onChanged: (v) => setLocal(() => status = v ?? status),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: opis,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Opis'),
                  ),
                  const SizedBox(height: 16),
                  // Photo picker in edit
                  PhotoPickerField(
                    base64: localPhoto,
                    onChanged: (b64) => setLocal(() => localPhoto = b64),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Anuluj'),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Zapisz'),
                        onPressed: () {
                          final repo = ref.read(mockRepoProvider);
                          repo.updateZgloszenie(
                            z.copyWith(
                              imie: imie.text.trim(),
                              nazwisko: nazw.text.trim(),
                              opis: opis.text.trim(),
                              typ: typ,
                              status: status,
                              photoBase64: localPhoto,
                              lastUpdated: DateTime.now(),
                            ),
                          );
                          Navigator.pop(context);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ],
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
    final data = _filtered(repo.getZgloszenia());

    return AppScaffold(
      appBar: AppBar(title: const Text('Zgłoszenia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SectionHeader(
              title: 'Nowe zgłoszenie',
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(() {}),
              ),
            ),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _imieCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Imię'),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Wymagane' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _nazCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Nazwisko'),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Wymagane' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _typSelected,
                            decoration: const InputDecoration(labelText: 'Typ'),
                            items: types
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(
                              () => _typSelected = v ?? _typSelected,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _status,
                            decoration:
                                const InputDecoration(labelText: 'Status'),
                            items: statusy
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _status = v ?? _status),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _opisCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Opis'),
                    ),
                    const SizedBox(height: 16),
                    // Photo picker (add form)
                    PhotoPickerField(
                      base64: _photoBase64,
                      onChanged: (b64) => setState(() => _photoBase64 = b64),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Dodaj zgłoszenie'),
                        onPressed: _add,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SectionHeader(
              title: 'Lista zgłoszeń',
              trailing: SizedBox(
                width: 260,
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    labelText: 'Szukaj',
                    suffixIcon: _query.isEmpty
                        ? const Icon(Icons.search)
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _search.clear();
                              setState(() {
                                _query = '';
                              });
                            },
                          ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                DropdownButton<String>(
                  value: _statusFilter,
                  items: const [
                    'WSZYSTKIE',
                    'NOWE',
                    'W TOKU',
                    'WERYFIKACJA',
                    'ZAMKNIĘTE'
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _statusFilter = v ?? _statusFilter),
                ),
                const SizedBox(width: 16),
                Text('Łącznie: ${data.length}'),
              ],
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(0),
              child: DataTablePro(
                sortColumnIndex: _sortCol,
                sortAscending: _asc,
                onSort: _onSort,
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Data')),
                  DataColumn(label: Text('Typ')),
                  DataColumn(label: Text('Osoba')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Foto')),
                ],
                rows: data.map((z) {
                  return DataRow(
                    cells: [
                      DataCell(Text('#${z.id}')),
                      DataCell(Text(_dtf.format(z.dataGodzina))),
                      DataCell(Text(z.typ)),
                      DataCell(Text('${z.imie} ${z.nazwisko}')),
                      DataCell(StatusChip(status: z.status)),
                      DataCell(
                        z.photoBase64 == null
                            ? const Icon(Icons.image_not_supported,
                                size: 20, color: Colors.grey)
                            : InkWell(
                                onTap: () => _showPhoto(z.photoBase64!),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.memory(
                                    base64Decode(z.photoBase64!),
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                      ),
                    ],
                    onSelectChanged: (_) => _editDialog(z),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}