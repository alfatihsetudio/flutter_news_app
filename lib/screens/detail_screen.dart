import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/article.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailScreen extends StatelessWidget {
  final Article article;
  const DetailScreen({super.key, required this.article});

  Future<void> _openUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _estimateReadTime(String? content) {
    if (content == null || content.isEmpty) return '';
    final words = content.split(RegExp(r'\s+')).length;
    final minutes = (words / 200).ceil();
    return '~${minutes} min read';
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = 'https://via.placeholder.com/800x400?text=No+Image';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Berita'),
        centerTitle: true,
      ),
      floatingActionButton: article.url != null
          ? FloatingActionButton.extended(
              onPressed: () => _openUrl(article.url),
              label: const Text('Buka sumber'),
              icon: const Icon(Icons.open_in_new),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (article.urlToImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: article.urlToImage!,
                height: 220,
                fit: BoxFit.cover,
                placeholder: (c, _) => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
                errorWidget: (c, _, __) => SizedBox(height: 220, child: Image.network(placeholder, fit: BoxFit.cover)),
              ),
            ),
          const SizedBox(height: 12),
          Text(article.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              if (article.author != null) Text('By ${article.author} • ', style: const TextStyle(fontSize: 12)),
              Text(article.publishedAt != null ? article.publishedAt!.replaceFirst('T', ' ').replaceFirst('Z', '') : '', style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              Text(_estimateReadTime(article.content), style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 12),
          Text(article.description ?? '', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          Text(article.content ?? '', style: const TextStyle(fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 40),
          if (article.url != null)
            ElevatedButton.icon(
              onPressed: () => _openUrl(article.url),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Buka sumber asli'),
            ),
        ],
      ),
    );
  }
}
