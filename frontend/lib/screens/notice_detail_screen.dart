import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import 'create_notice_screen.dart';

class NoticeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> notice;

  const NoticeDetailScreen({super.key, required this.notice});

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  final _commentController = TextEditingController();
  late Map<String, dynamic> _notice;
  late Future<List<dynamic>> _commentsFuture;
  bool _isPosting = false;

  int get _noticeId => _notice['id'] as int;

  bool _isOwner(Map<String, dynamic>? item) =>
      AuthStorage.username != null && item?['author']?['username'] == AuthStorage.username;

  @override
  void initState() {
    super.initState();
    _notice = widget.notice;
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

  String _cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');

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
      _showMessage(_cleanError(e));
    }
  }

  Future<void> _deleteComment(int commentId) async {
    try {
      await ApiService.deleteComment(commentId);
      if (!mounted) return;
      _reloadComments();
    } catch (e) {
      if (!mounted) return;
      _showMessage(_cleanError(e));
    }
  }

  Future<void> _editNotice() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateNoticeScreen(existing: _notice)),
    );
    if (saved != true || !mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this notice?'),
        content: const Text('Its comments will be removed too.'),
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
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage(_cleanError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final notice = _notice;
    final author = notice['author']?['username'] ?? 'Anonymous';
    final isOwner = _isOwner(notice);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit notice',
              onPressed: _editNotice,
            ),
          if (isOwner)
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
                        _cleanError(snapshot.error!),
                        style: const TextStyle(color: Colors.red),
                      );
                    }
                    final comments = snapshot.data ?? [];
                    if (comments.isEmpty) {
                      return const Text('No comments yet.');
                    }
                    return Column(
                      children: comments.map<Widget>((c) {
                        final commentOwner = _isOwner(
                          {'author': c['author']},
                        );
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(c['content'] ?? ''),
                          subtitle: Text(c['author']?['username'] ?? 'Anonymous'),
                          trailing: commentOwner
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  tooltip: 'Delete comment',
                                  onPressed: () => _deleteComment(c['id'] as int),
                                )
                              : null,
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
