import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class ComplaintFormPage extends StatefulWidget {
  const ComplaintFormPage({super.key});

  @override
  State<ComplaintFormPage> createState() => _ComplaintFormPageState();
}

class _ComplaintFormPageState extends State<ComplaintFormPage> {
  final _formKey = GlobalKey<FormState>();
  ComplaintType _type = ComplaintType.other;
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final bool _sending = false;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final app = Provider.of<AppProvider>(context, listen: false);
    if (app.currentUser == null) {
      // For guests create a temporary user id
      app.createComplaint(
        type: _type,
        subject: _subjectCtrl.text.trim(),
        description: _descCtrl.text.trim(),
      );
    } else {
      app.createComplaint(
        type: _type,
        subject: _subjectCtrl.text.trim(),
        description: _descCtrl.text.trim(),
      );
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Şikayət göndərildi')));

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şikayət Göndər')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<ComplaintType>(
                initialValue: _type,
                items: ComplaintType.values
                    .map(
                      (e) => DropdownMenuItem(value: e, child: Text(e.label)),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => _type = v ?? ComplaintType.other),
                decoration: const InputDecoration(labelText: 'Növ'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(labelText: 'Mövzu'),
                validator: (v) => v == null || v.isEmpty ? 'Daxil edin' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Təsvir'),
                maxLines: 5,
                validator: (v) => v == null || v.isEmpty ? 'Daxil edin' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _sending ? null : _submit,
                child: const Text('Göndər'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
