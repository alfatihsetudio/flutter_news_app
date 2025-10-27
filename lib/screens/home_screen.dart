import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/article.dart';
import '../services/api_service.dart';
import '../widgets/article_tile.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  List<Article> articles = [];
  bool loading = true;
  String? error;
  final TextEditingController _searchController = TextEditingController();
  String currentQuery = '';
  String currentCategory = '';
  final List<String> categories = ['', 'business', 'entertainment', 'general', 'health', 'science', 'sports', 'technology'];

  @override
  void initState() {
    super.initState();
    _loadHeadlines();
    _searchController.addListener(() { setState(() {}); });
  }

  Future<void> _loadHeadlines() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await apiService.fetchTopHeadlines(country: 'us', category: currentCategory.isEmpty ? null : currentCategory);
      setState(() {
        articles = data;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      currentQuery = '';
      await _loadHeadlines();
      return;
    }
    setState(() {
      loading = true;
      error = null;
      currentQuery = q;
    });
    try {
      final data = await apiService.searchArticles(q);
      setState(() {
        articles = data;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            height: 100,
            child: Row(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(width: 120, height: 100, color: Colors.white),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100, child: Container(width: double.infinity, height: 16, color: Colors.white)),
                        const SizedBox(height: 8),
                        Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100, child: Container(width: double.infinity, height: 12, color: Colors.white)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (loading) {
      return _buildShimmer();
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $error'),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _loadHeadlines, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    if (articles.isEmpty) {
      return const Center(child: Text('Tidak ada berita.'));
    }
    return RefreshIndicator(
      onRefresh: currentQuery.isEmpty ? _loadHeadlines : () => _search(currentQuery),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final a = articles[index];
          return ArticleTile(
            article: a,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailScreen(article: a)),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String v) => _search(v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Berita Hari Ini'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: currentQuery.isEmpty ? _loadHeadlines : () => _search(currentQuery),
            tooltip: 'Refresh',
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: _onSearchSubmitted,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Cari berita (contoh: teknologi, sepakbola)...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _search('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemBuilder: (context, index) {
                      final c = categories[index];
                      final display = c.isEmpty ? 'All' : c[0].toUpperCase() + c.substring(1);
                      final selected = c == currentCategory;
                      return ChoiceChip(
                        label: Text(display),
                        selected: selected,
                        onSelected: (_) async {
                          setState(() {
                            currentCategory = c;
                          });
                          await _loadHeadlines();
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: categories.length,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }
}
