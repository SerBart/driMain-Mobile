// WERSJA (jeśli nadal potrzebujesz starego ekranu) – odkomentowana obsługa zdjęć.
// Jeżeli już nie używasz – możesz pominąć ten plik lub usunąć stare zakomentowane fragmenty.
// Uwaga: nie pokazuję całej klasy (bo w repo był mocno zakomentowany) – dostosuj jeśli chcesz zachować.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/models/zgloszenie.dart';
import '../../core/providers/app_providers.dart';

class ZgloszeniaListScreen extends ConsumerStatefulWidget {
  const ZgloszeniaListScreen({super.key});
  @override
  ConsumerState<ZgloszeniaListScreen> createState() =>
      _ZgloszeniaListScreenState();
}

class _ZgloszeniaListScreenState
    extends ConsumerState<ZgloszeniaListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imieCtrl = TextEditingController();
  final _nazCtrl = TextEditingController();
  final _opisCtrl = TextEditingController();
  String _status = 'NOWE';
  String _typ = 'Usterka';
  String? _photoBase64;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _statusFilter = 'WSZYSTKIE';
  int _sortColumn = 1;
  bool _sortAsc = false;

  final DateFormat _dtf = DateFormat('yyyy-MM-dd HH:mm');
  static const types = ['Usterka', 'Awaria', 'Przezbrojenie'];

  @override
  void dispose() {
    _imieCtrl.dispose();
    _nazCtrl.dispose();
    _opisCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    _imieCtrl.clear();
    _nazCtrl.clear();
    _opisCtrl.clear();
    _status = 'NOWE';
    _typ = 'Usterka';
    _photoBase64 = null;
  }

  Future<void> _pickPhoto({bool camera = false}) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _photoBase64 = base64Encode(bytes));
    }
  }

  void _add() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(mockRepoProvider).addZgloszenie(
          Zgloszenie(
            id: 0,
            imie: _imieCtrl.text.trim(),
            nazwisko: _nazCtrl.text.trim(),
            typ: _typ,
            dataGodzina: DateTime.now(),
            opis: _opisCtrl.text.trim(),
            status: _status,
            photoBase64: _photoBase64,
          ),
        );
    _reset();
    setState(() {});
  }

  List<Zgloszenie> _filteredAndSorted(List<Zgloszenie> all) {
    var base = List<Zgloszenie>.from(all);
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      base = base.where((z) {
        return z.typ.toLowerCase().contains(q) ||
            z.opis.toLowerCase().contains(q) ||
            z.imie.toLowerCase().contains(q) ||
            z.nazwisko.toLowerCase().contains(q) ||
            z.status.toLowerCase().contains(q) ||
            z.id.toString() == q;
      }).toList();
    }
    if (_statusFilter != 'WSZYSTKIE') {
      base = base
          .where((z) => z.status.toUpperCase() == _statusFilter)
          .toList();
    }
    base.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
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
          cmp =
              ('${a.imie} ${a.nazwisko}').compareTo('${b.imie} ${b.nazwisko}');
          break;
        case 4:
          cmp = a.status.compareTo(b.status);
          break;
        default:
          cmp = b.id.compareTo(a.id);
      }
      return _sortAsc ? cmp : -cmp;
    });
    return base;
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

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(mockRepoProvider);
    final data = _filteredAndSorted(repo.getZgloszenia());

    return Scaffold(
      appBar: AppBar(title: const Text('Zgłoszenia (stare)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Wrap(
                runSpacing: 12,
                spacing: 12,
                children: [
                  SizedBox(
                    width: 180,
                    child: TextFormField(
                      controller: _imieCtrl,
                      decoration: const InputDecoration(labelText: 'Imię'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Wymagane' : null,
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: TextFormField(
                      controller: _nazCtrl,
                      decoration: const InputDecoration(labelText: 'Nazwisko'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Wymagane' : null,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String>(
                      value: _typ,
                      decoration: const InputDecoration(labelText: 'Typ'),
                      items: types
                          .map((t) =>
                              DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _typ = v ?? _typ),
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        'NOWE',
                        'W TOKU',
                        'WERYFIKACJA',
                        'ZAMKNIĘTE'
                      ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _status = v ?? _status),
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: TextFormField(
                      controller: _opisCtrl,
                      maxLines: 1,
                      decoration: const InputDecoration(labelText: 'Opis'),
                    ),
                  ),
                  // mini photo block
                  SizedBox(
                    width: 260,
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _photoBase64 == null
                              ? null
                              : () => _showPhoto(_photoBase64!),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade200,
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _photoBase64 == null
                                ? const Icon(Icons.image, size: 22)
                                : Image.memory(
                                    base64Decode(_photoBase64!),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () => _pickPhoto(camera: false),
                              child: Text(
                                  _photoBase64 == null ? 'Zdjęcie' : 'Zmień'),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => _pickPhoto(camera: true),
                                  child: const Text('Aparat'),
                                ),
                                if (_photoBase64 != null)
                                  TextButton(
                                    onPressed: () =>
                                        setState(() => _photoBase64 = null),
                                    child: const Text(
                                      'Usuń',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                    label: const Text('Dodaj'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Szukaj',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  sortColumnIndex: _sortColumn,
                  sortAscending: _sortAsc,
                  columns: [
                    DataColumn(
                      label: const Text('ID'),
                      onSort: (i, asc) =>
                          setState(() => {_sortColumn = i, _sortAsc = asc}),
                    ),
                    DataColumn(
                      label: const Text('Data'),
                      onSort: (i, asc) =>
                          setState(() => {_sortColumn = i, _sortAsc = asc}),
                    ),
                    const DataColumn(label: Text('Typ')),
                    const DataColumn(label: Text('Osoba')),
                    const DataColumn(label: Text('Status')),
                    const DataColumn(label: Text('Foto')),
                  ],
                  rows: data.map((z) {
                    return DataRow(
                      cells: [
                        DataCell(Text(z.id.toString())),
                        DataCell(Text(_dtf.format(z.dataGodzina))),
                        DataCell(Text(z.typ)),
                        DataCell(Text('${z.imie} ${z.nazwisko}')),
                        DataCell(Text(z.status)),
                        DataCell(
                          z.photoBase64 == null
                              ? const Icon(Icons.image_not_supported,
                                  size: 18, color: Colors.grey)
                              : InkWell(
                                  onTap: () => _showPhoto(z.photoBase64!),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.memory(
                                      base64Decode(z.photoBase64!),
                                      width: 42,
                                      height: 42,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}