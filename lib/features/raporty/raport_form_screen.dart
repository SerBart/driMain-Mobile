import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/raport.dart';
import '../../core/models/maszyna.dart';

class RaportFormScreen extends ConsumerStatefulWidget {
  final Raport? existing;
  final int? raportId; // NOWE - opcjonalne ID do załadowania

  const RaportFormScreen({
    super.key,
    this.existing,
    this.raportId,
  });

  @override
  ConsumerState<RaportFormScreen> createState() => _RaportFormScreenState();
}

class _RaportFormScreenState extends ConsumerState<RaportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Maszyna? _maszyna;
  final _typNaprawyCtrl = TextEditingController();
  final _opisCtrl = TextEditingController();
  DateTime? _dataNaprawy;
  TimeOfDay? _czasOd;
  TimeOfDay? _czasDo;
  Raport? _loaded; // przechowuje raport jeśli wczytany po ID

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    // Priorytet: existing > raportId > świeży formularz
    Raport? base = widget.existing;
    if (base == null && widget.raportId != null) {
      final repo = ref.read(mockRepoProvider);
      base = repo.getRaportById(widget.raportId!);
      _loaded = base;
    }
    if (base != null) {
      _maszyna = base.maszyna;
      _typNaprawyCtrl.text = base.typNaprawy;
      _opisCtrl.text = base.opis;
      _dataNaprawy = base.dataNaprawy;
      _czasOd = TimeOfDay(hour: base.czasOd.hour, minute: base.czasOd.minute);
      _czasDo = TimeOfDay(hour: base.czasDo.hour, minute: base.czasDo.minute);
    }
  }

  @override
  void dispose() {
    _typNaprawyCtrl.dispose();
    _opisCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDate: _dataNaprawy ?? now,
    );
    if (picked != null) setState(() => _dataNaprawy = picked);
  }

  Future<void> _pickTime({required bool from}) async {
    final base = from ? _czasOd : _czasDo;
    final picked = await showTimePicker(
      context: context,
      initialTime: base ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (from) {
          _czasOd = picked;
        } else {
          _czasDo = picked;
        }
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_maszyna == null || _dataNaprawy == null || _czasOd == null || _czasDo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uzupełnij maszynę, datę i czas')),
      );
      return;
    }
    final repo = ref.read(mockRepoProvider);

    final dtOd = DateTime(
      _dataNaprawy!.year,
      _dataNaprawy!.month,
      _dataNaprawy!.day,
      _czasOd!.hour,
      _czasOd!.minute,
    );
    final dtDo = DateTime(
      _dataNaprawy!.year,
      _dataNaprawy!.month,
      _dataNaprawy!.day,
      _czasDo!.hour,
      _czasDo!.minute,
    );

    final idToUse = _loaded?.id ?? widget.existing?.id ?? 0;

    final raport = Raport(
      id: idToUse,
      maszyna: _maszyna!,
      typNaprawy: _typNaprawyCtrl.text.trim(),
      opis: _opisCtrl.text.trim(),
      osoba: _loaded?.osoba ?? widget.existing?.osoba, // dopasuj wg modelu
      status: _loaded?.status ?? widget.existing?.status ?? 'NOWY',
      dataNaprawy: _dataNaprawy!,
      czasOd: dtOd,
      czasDo: dtDo,
      partUsages: _loaded?.partUsages ?? widget.existing?.partUsages ?? [],
    );

    repo.upsertRaport(raport);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(mockRepoProvider);
    final maszyny = repo.getMaszyny();

    final isEdit = _loaded != null || widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edytuj raport' : 'Dodaj raport'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<Maszyna>(
                value: _maszyna,
                decoration: const InputDecoration(labelText: 'Maszyna'),
                items: maszyny
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.nazwa)))
                    .toList(),
                onChanged: (v) => setState(() => _maszyna = v),
                validator: (v) => v == null ? 'Wybierz maszynę' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _typNaprawyCtrl,
                decoration: const InputDecoration(labelText: 'Typ naprawy'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Wymagane' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _opisCtrl,
                decoration: const InputDecoration(labelText: 'Opis'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _WhiteButton(
                    label: _dataNaprawy == null
                        ? 'Data naprawy'
                        : 'Data: ${_dataNaprawy!.toIso8601String().substring(0, 10)}',
                    icon: Icons.calendar_month_outlined,
                    onTap: _pickDate,
                  ),
                  _WhiteButton(
                    label: _czasOd == null ? 'Czas od' : 'Od: ${_czasOd!.format(context)}',
                    icon: Icons.schedule_outlined,
                    onTap: () => _pickTime(from: true),
                  ),
                  _WhiteButton(
                    label: _czasDo == null ? 'Czas do' : 'Do: ${_czasDo!.format(context)}',
                    icon: Icons.schedule,
                    onTap: () => _pickTime(from: false),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: Text(isEdit ? 'Zapisz zmiany' : 'Zapisz raport'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhiteButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _WhiteButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.black87),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}