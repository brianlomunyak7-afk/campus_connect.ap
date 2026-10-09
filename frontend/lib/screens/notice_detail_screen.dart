import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';

class NoticeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> notice;

  const NoticeDetailScreen({super.key, required this.notice});

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  final _commentController = TextEditingController();
  late Future<List<dynamic>> _commentsFuture;
  bool _isPosting = false;

  int get _noticeId => widget.notice['id'] as int;

  // Usernames are unique, so this is enough to tell if the notice is yours
  bool get _isAuthor =>
      AuthStorage.username != null &&
      widget.notice['author']?['username'] == AuthStorage.username;

  @override
  void initState() {
    super.initState();
    _commentsFuture = ApiService.fetchComments(_noticeId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _reloadComments() {
    setState(() => _commentsFuture = ApiService.fetchComments(_noticeId));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      await ApiService.addComment(_noticeId, text);
      if (!mounted) return;
      _commentController.clear();
      setState(() => _isPosting = false);
      _reloadComments();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPosting = false);
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this notice?'),
        content: const Text('This also removes its comments.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.deleteNotice(_noticeId);
      if (!mounted) return;
      // Pop back to the list and tell it to reload
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final notice = widget.notice;
    final author = notice['author']?['username'] ?? 'Anonymous';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice'),
        actions: [
          if (_isAuthor)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete notice',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  notice['title'] ?? 'Untitled',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${notice['category'] ?? 'General'} · posted by $author',
                  style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
                Text(notice['body'] ?? '', style: const TextStyle(fontSize: 16)),
                const Divider(height: 40),
                const Text(
                  'Comments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<dynamic>>(
                  future: _commentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text(
                        snapshot.error.toString().replaceFirst('Exception: ', ''),
                        style: const TextStyle(color: Colors.red),
                      );
                    }
                    final comments = snapshot.data ?? [];
                    if (comments.isEmpty) {
                      return const Text('No comments yet.');
                    }
                    return Column(
                      children: comments.map<Widget>((c) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(c['content'] ?? ''),
                          subtitle: Text(c['author']?['username'] ?? 'Anonymous'),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          if (AuthStorage.isLoggedIn)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Write a comment…',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: _isPosting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      onPressed: _isPosting ? null : _postComment,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
