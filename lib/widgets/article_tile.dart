// lib/widgets/article_tile.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/article.dart';

class ArticleTile extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  final double imageWidth;
  final double imageHeight;

  const ArticleTile({
    super.key,
    required this.article,
    required this.onTap,
    this.imageWidth = 120,
    this.imageHeight = 100,
  });

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('d MMM • HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = 'https://via.placeholder.com/400x300?text=No+Image';
    final imageUrl = article.urlToImage ?? placeholder;
    final source = (article.author != null && article.author!.isNotEmpty) ? article.author! : 'Unknown source';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Image with Hero for nice transition to detail
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                  child: Hero(
                    tag: article.url ?? article.title,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: imageWidth,
                      height: imageHeight,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: imageWidth,
                        height: imageHeight,
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: imageWidth,
                        height: imageHeight,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 36, color: Colors.black26),
                      ),
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Source chip + date at top row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                source.length > 18 ? '${source.substring(0, 15)}...' : source,
                                style: TextStyle(
                                  color: Colors.indigo.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDate(article.publishedAt),
                              style: TextStyle(fontSize: 11, color: Colors.black54),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Title
                        Text(
                          article.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.1),
                        ),
                        const SizedBox(height: 6),

                        // Description / snippet
                        Text(
                          article.description ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Colors.black87.withOpacity(0.9)),
                        ),

                        const SizedBox(height: 8),

                        // Action row (small icons)
                        Row(
                          children: [
                            Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.black45),
                            const SizedBox(width: 6),
                            Text('Read', style: TextStyle(fontSize: 12, color: Colors.black45)),
                            const Spacer(),
                            // small chevron to hint navigable card
                            Icon(Icons.chevron_right, color: Colors.black26),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
