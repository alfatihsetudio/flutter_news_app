// lib/widgets/map_search_suggestions.dart
import 'package:flutter/material.dart';
import '../models/place.dart';

typedef OnPlaceSelected = void Function(Place place);

class MapSearchSuggestions extends StatelessWidget {
  final List<Place> suggestions;
  final OnPlaceSelected onPlaceSelected;
  final bool loading;
  final String query;

  const MapSearchSuggestions({
    super.key,
    required this.suggestions,
    required this.onPlaceSelected,
    this.loading = false,
    this.query = '',
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (query.isEmpty) return const SizedBox.shrink();

    if (suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text('Tidak ada hasil untuk "$query".', style: TextStyle(color: Colors.black54)),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 4,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final p = suggestions[index];
          return ListTile(
            title: Text(p.name.isNotEmpty ? p.name : p.displayName),
            subtitle: Text(p.displayName, maxLines: 2, overflow: TextOverflow.ellipsis),
            onTap: () => onPlaceSelected(p),
          );
        },
      ),
    );
  }
}
