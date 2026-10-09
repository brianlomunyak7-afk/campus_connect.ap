import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../widgets/animated_background.dart';
import 'create_notice_screen.dart';
import 'login_screen.dart';
import 'notice_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _pageSize = 20;

  final Color primaryColor = const Color(0xFF2563EB);
  final Color accentColor = const Color(0xFFF59E0B);
  final List<String> categories = ['All', 'Event', 'Job', 'Lost & Found', 'General'];

  String selectedCategory = 'All';
  List<dynamic> _notices = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage(reset: true);
  }

  String? get _categoryParam => selectedCategory == 'All' ? null : selectedCategory;

  Future<void> _loadPage({required bool reset}) async {
    if (_loadingMore) return;
    final offset = reset ? 0 : _notices.length;

    setState(() {
      _error = null;
      if (reset) {
        _loading = true;
      } else {
        _loadingMore = true;
      }
    });

    try {
      final page = await ApiService.fetchNotices(
        category: _categoryParam,
        offset: offset,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _notices = reset ? page : [..._notices, ...page];
        _hasMore = page.length == _pageSize;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _selectCategory(String category) {
    if (category == selectedCategory) return;
    setState(() => selectedCategory = category);
    _loadPage(reset: true);
  }

  Future<void> _openCreateNotice() async {
    final posted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateNoticeScreen()),
    );
    if (posted == true) _loadPage(reset: true);
  }

  Future<void> _openNotice(Map<String, dynamic> notice) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => NoticeDetailScreen(notice: notice)),
    );
    if (changed == true) _loadPage(reset: true);
  }

  Future<void> _logout() async {
    await AuthStorage.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'CampusConnect 🎓',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.white24,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Log out',
              onPressed: _logout,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openCreateNotice,
          backgroundColor: accentColor,
          child: const Icon(Icons.add_comment, color: Colors.white),
        ),
        body: Column(
          children: [
            SizedBox(
              height: 60,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: accentColor.withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: isSelected ? primaryColor : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) _selectCategory(category);
                      },
                    ),
                  );
                },
              ),
            ),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Oops! $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _loadPage(reset: true),
              child: const Text('Try again', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (_notices.isEmpty) {
      return const Center(
        child: Text('No notices yet!', style: TextStyle(color: Colors.white)),
      );
    }

    final extraItems = _hasMore ? 1 : 0;
    return RefreshIndicator(
      onRefresh: () => _loadPage(reset: true),
      child: ListView.builder(
        itemCount: _notices.length + extraItems,
        itemBuilder: (context, index) {
          if (index >= _notices.length) {
            return _buildLoadMore();
          }
          return _buildNoticeCard(_notices[index]);
        },
      ),
    );
  }

  Widget _buildLoadMore() {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return Center(
      child: TextButton(
        onPressed: () => _loadPage(reset: false),
        child: const Text('Load more', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildNoticeCard(Map<String, dynamic> notice) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: () => _openNotice(notice),
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(
          notice['title'] ?? 'Untitled',
          style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8.0),
            Text(
              notice['body'] ?? '',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    notice['category'] ?? 'General',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Posted by ${notice['author']?['username'] ?? "Anonymous"}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
