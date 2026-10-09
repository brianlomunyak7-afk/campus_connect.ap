import 'package:flutter/material.dart';
import '../services/api_service.dart';

const List<String> noticeCategories = ['Event', 'Job', 'Lost & Found', 'General'];

class CreateNoticeScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const CreateNoticeScreen({super.key, this.existing});

  @override
  State<CreateNoticeScreen> createState() => _CreateNoticeScreenState();
}

class _CreateNoticeScreenState extends State<CreateNoticeScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late String _category;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?['title'] ?? '');
    _bodyController = TextEditingController(text: existing?['body'] ?? '');
    _category = existing?['category'] ?? noticeCategories.first;
  }

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
      if (_isEditing) {
        await ApiService.updateNotice(
          widget.existing!['id'] as int,
          title: title,
          body: body,
          category: _category,
        );
      } else {
        await ApiService.createNotice(title: title, body: body, category: _category);
      }
      if (!mounted) return;
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit notice' : 'New notice')),
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
                : Text(_isEditing ? 'Save changes' : 'Post notice'),
          ),
        ],
      ),
    );
  }
}
