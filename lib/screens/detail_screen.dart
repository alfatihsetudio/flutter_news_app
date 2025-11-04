// lib/screens/detail_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/article.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class DetailScreen extends StatefulWidget {
  final Article article;
  const DetailScreen({super.key, required this.article});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  bool _isBookmarked = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _loadBookmark();
    _configureTts();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _configureTts() async {
    // Disable TTS for web (flutter_tts has limited web support)
    if (kIsWeb) return;
    try {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      _tts.setStartHandler(() {
        setState(() {
          _isSpeaking = true;
        });
      });
      _tts.setCompletionHandler(() {
        setState(() {
          _isSpeaking = false;
        });
      });
      _tts.setErrorHandler((err) {
        setState(() {
          _isSpeaking = false;
        });
      });
    } catch (_) {
      // ignore TTS config errors
    }
  }

  Future<void> _loadBookmark() async {
    final sp = await SharedPreferences.getInstance();
    final List<String>? list = sp.getStringList('bookmarks');
    final url = widget.article.url ?? '';
    setState(() {
      _isBookmarked = list?.contains(url) ?? false;
    });
  }

  Future<void> _toggleBookmark() async {
    final sp = await SharedPreferences.getInstance();
    final List<String> list = sp.getStringList('bookmarks') ?? <String>[];
    final url = widget.article.url ?? '';
    setState(() {
      if (_isBookmarked) {
        list.remove(url);
        _isBookmarked = false;
      } else {
        if (url.isNotEmpty && !list.contains(url)) list.add(url);
        _isBookmarked = true;
      }
      sp.setStringList('bookmarks', list);
    });
    final snack = _isBookmarked ? 'Disimpan ke bookmarks' : 'Dihapus dari bookmarks';
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snack)));
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka sumber.')));
    }
  }

  Future<void> _shareArticle() async {
    final url = widget.article.url;
    final title = widget.article.title ?? '';
    if (url != null && url.isNotEmpty) {
      await Share.share('$title\n\n${_linkPreview(url)}');
    } else {
      await Share.share(title);
    }
  }

  String _linkPreview(String url) => url;

  String _estimateReadTime(String? content) {
    if (content == null || content.trim().isEmpty) return '';
    final words = content.split(RegExp(r'\s+')).length;
    final minutes = (words / 200).ceil();
    return '~$minutes min read';
  }

  Future<void> _toggleTts() async {
    if (kIsWeb) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Text-to-speech tidak didukung di web'))); 
      return;
    }
    final content = (widget.article.content ?? widget.article.description) ?? widget.article.title ?? '';
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
    } else {
      await _tts.speak(content);
      setState(() => _isSpeaking = true);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat.yMMMMd().add_jm().format(dt.toLocal());
    } catch (e) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final placeholder = 'https://via.placeholder.com/1200x600?text=No+Image';
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 300,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              actions: [
                IconButton(
                  icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                  onPressed: _toggleBookmark,
                  tooltip: _isBookmarked ? 'Hapus bookmark' : 'Simpan',
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: _shareArticle,
                  tooltip: 'Share',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                collapseMode: CollapseMode.parallax,
                title: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: article.urlToImage ?? placeholder,
                      fit: BoxFit.cover,
                      placeholder: (c, s) => Container(color: Colors.grey.shade300),
                      errorWidget: (c, s, e) => Image.network(placeholder, fit: BoxFit.cover),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black26],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Row(
                      children: [
                        if (article.author != null)
                          Text('By ${article.author}', style: textTheme.bodySmall),
                        if (article.author != null) const SizedBox(width: 8),
                        Text(_formatDate(article.publishedAt), style: textTheme.bodySmall?.copyWith(color: Colors.black54)),
                        const Spacer(),
                        if ((_estimateReadTime(article.content)).isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(20)),
                            child: Text(_estimateReadTime(article.content), style: const TextStyle(fontSize: 12, color: Colors.indigo)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(article.title, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (article.description != null && article.description!.isNotEmpty)
                      Text(article.description!, style: textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey.shade200, thickness: 1),
                    const SizedBox(height: 12),
                    Text(article.content ?? '', style: textTheme.bodyLarge?.copyWith(height: 1.6)),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _openUrl(article.url),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Buka sumber'),
                          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                        OutlinedButton.icon(
                          onPressed: _toggleTts,
                          icon: Icon(_isSpeaking ? Icons.volume_off : Icons.volume_up),
                          label: Text(_isSpeaking ? 'Stop' : 'Dengarkan'),
                          style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Text('Related', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text('Suggestions engine not yet implemented — can be added later.'),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
