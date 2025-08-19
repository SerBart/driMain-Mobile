import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/raport.dart';
import '../../core/models/maszyna.dart';
import '../../ui/date_time_pickers.dart';
import '../../ui/primary_buttons.dart';

class RaportFormScreen extends ConsumerStatefulWidget {
  final Raport? existing;
  final int? raportId;

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
  Raport? _loaded;

  bool get _isEdit => _loaded != null || widget.existing != null;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  void _hydrate() {
    Raport? base = widget.existing;
    if (base == null && widget.raportId != null) {
      base = ref.read(mockRepoProvider).getRaportById(widget.raportId!);
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
    final picked = await pickDate(context: context, initial: _dataNaprawy);
    if (picked != null) setState(() => _dataNaprawy = picked);
  }

  Future<void> _pickTime({required bool from}) async {
    final picked = await pickTime(
      context: context,
      initial: from ? _czasOd : _czasDo,
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

  String? _validateTimes() {
    if (_czasOd == null || _czasDo == null || _dataNaprawy == null) return null;
    final start = DateTime(
      _dataNaprawy!.year,
      _dataNaprawy!.month,
      _dataNaprawy!.day,
      _czasOd!.hour,
      _czasOd!.minute,
    );
    final end = DateTime(
      _dataNaprawy!.year,
      _dataNaprawy!.month,
      _dataNaprawy!.day,
      _czasDo!.hour,
      _czasDo!.minute,
    );
    if (end.isBefore(start)) {
      return 'Czas "Do" nie może być wcześniejszy niż "Od"';
    }
    return null;
  }

  void _save() {
    final timesErr = _validateTimes();
    if (timesErr != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(timesErr)));
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_maszyna == null ||
        _dataNaprawy == null ||
        _czasOd == null ||
        _czasDo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uzupełnij maszynę, datę oraz godziny')),
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

    final id = _loaded?.id ?? widget.existing?.id ?? 0;
    final partUsages = _loaded?.partUsages ?? widget.existing?.partUsages ?? [];

    final raport = Raport(
      id: id,
      maszyna: _maszyna,
      typNaprawy: _typNaprawyCtrl.text.trim(),
      opis: _opisCtrl.text.trim(),
      osoba: _loaded?.osoba ?? widget.existing?.osoba,
      status: _loaded?.status ?? widget.existing?.status ?? 'NOWY',
      dataNaprawy: _dataNaprawy!,
      czasOd: dtOd,
      czasDo: dtDo,
      partUsages: partUsages,
    );

    repo.upsertRaport(raport);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(mockRepoProvider);
    final maszyny = repo.getMaszyny();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edytuj raport' : 'Nowy raport'),
        actions: [
          IconButton(
            tooltip: 'Zapisz',
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
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
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wymagane' : null,
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
                _PickerButton(
                  label: _dataNaprawy == null
                      ? 'Data'
                      : 'Data: ${_dataNaprawy!.toIso8601String().substring(0, 10)}',
                  icon: Icons.calendar_month_outlined,
                  onTap: _pickDate,
                ),
                _PickerButton(
                  label: _czasOd == null
                      ? 'Czas od'
                      : 'Od: ${_czasOd!.format(context)}',
                  icon: Icons.schedule_outlined,
                  onTap: () => _pickTime(from: true),
                ),
                _PickerButton(
                  label: _czasDo == null
                      ? 'Czas do'
                      : 'Do: ${_czasDo!.format(context)}',
                  icon: Icons.schedule,
                  onTap: () => _pickTime(from: false),
                ),
              ],
            ),
            if (_validateTimes() != null) ...[
              const SizedBox(height: 8),
              Text(
                _validateTimes()!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 32),
            PrimaryButton(
              label: _isEdit ? 'Zapisz zmiany' : 'Zapisz raport',
              icon: Icons.save,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
