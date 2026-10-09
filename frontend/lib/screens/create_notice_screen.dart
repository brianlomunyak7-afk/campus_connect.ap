import 'package:flutter/material.dart';
import '../services/api_service.dart';

// Categories must match the backend's NoticeCategory values exactly
const List<String> noticeCategories = ['Event', 'Job', 'Lost & Found', 'General'];

class CreateNoticeScreen extends StatefulWidget {
  const CreateNoticeScreen({super.key});

  @override
  State<CreateNoticeScreen> createState() => _CreateNoticeScreenState();
}

class _CreateNoticeScreenState extends State<CreateNoticeScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _category = noticeCategories.first;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      _showMessage('Please add a title and a description');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ApiService.createNotice(title: title, body: body, category: _category);
      if (!mounted) return;
      // Tell the home screen to reload the notice list
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New notice')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _titleController,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bodyController,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Details',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: noticeCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post notice'),
          ),
        ],
      ),
    );
  }
}
