import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/group_provider.dart';

class CreateChallengeScreen extends ConsumerStatefulWidget {
  final int groupId;
  const CreateChallengeScreen({super.key, required this.groupId});

  @override
  ConsumerState<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  String _type = 'STEPS';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Create Challenge', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Challenge Title'),
              _field(_titleCtrl, 'e.g. 10K Steps Daily'),

              const SizedBox(height: 16),
              _label('Description (optional)'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: _inputDec('Short description of the challenge'),
              ),

              const SizedBox(height: 16),
              _label('Type'),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'STEPS', label: Text('Steps'), icon: Icon(Icons.directions_walk)),
                  ButtonSegment(value: 'CALORIES', label: Text('Calories'), icon: Icon(Icons.local_fire_department)),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() => _type = v.first),
              ),

              const SizedBox(height: 16),
              _label('Target (${_type == 'STEPS' ? 'steps' : 'kcal'})'),
              TextFormField(
                controller: _targetCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDec(_type == 'STEPS' ? 'e.g. 70000' : 'e.g. 2000'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Must be a number';
                  return null;
                },
              ),

              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _datePicker('Start Date', _startDate, (d) => setState(() => _startDate = d))),
                const SizedBox(width: 12),
                Expanded(child: _datePicker('End Date', _endDate, (d) => setState(() => _endDate = d))),
              ]),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Challenge',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      );

  Widget _field(TextEditingController ctrl, String hint) => TextFormField(
        controller: ctrl,
        decoration: _inputDec(hint),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      );

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  Widget _datePicker(String label, DateTime date, Function(DateTime) onChanged) => GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) onChanged(picked);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              const SizedBox(height: 4),
              Text('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(challengesMutationProvider.notifier).createChallenge(
            groupId: widget.groupId,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            type: _type,
            targetValue: int.parse(_targetCtrl.text.trim()),
            startDate: _fmt(_startDate),
            endDate: _fmt(_endDate),
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _loading = false);
    }
  }
}
