// lib/widgets/map_marker_info.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place.dart';
import 'package:url_launcher/url_launcher.dart';

class MapMarkerInfo extends StatefulWidget {
  final Place place;
  final VoidCallback? onSavedChanged;

  const MapMarkerInfo({super.key, required this.place, this.onSavedChanged});

  @override
  State<MapMarkerInfo> createState() => _MapMarkerInfoState();
}

class _MapMarkerInfoState extends State<MapMarkerInfo> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList('maps_favorites') ?? <String>[];
    final found = raw.any((s) {
      try {
        final m = json.decode(s) as Map<String, dynamic>;
        return m['id'] == widget.place.id;
      } catch (_) {
        return false;
      }
    });
    setState(() => _saved = found);
  }

  Future<void> _toggleSave() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList('maps_favorites') ?? <String>[];
    if (_saved) {
      raw.removeWhere((s) {
        try {
          final m = json.decode(s) as Map<String, dynamic>;
          return m['id'] == widget.place.id;
        } catch (_) {
          return false;
        }
      });
    } else {
      raw.add(json.encode(widget.place.toJson()));
    }
    await sp.setStringList('maps_favorites', raw);
    setState(() => _saved = !_saved);
    if (widget.onSavedChanged != null) widget.onSavedChanged!();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_saved ? 'Disimpan ke favorites' : 'Dihapus dari favorites')));
  }

  Future<void> _openExternal() async {
    final url = 'https://www.openstreetmap.org/?mlat=${widget.place.lat}&mlon=${widget.place.lon}#map=18/${widget.place.lat}/${widget.place.lon}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka eksternal.')));
    }
  }

  Future<void> _share() async {
    final url = 'https://www.openstreetmap.org/?mlat=${widget.place.lat}&mlon=${widget.place.lon}';
    // Use share_plus in screens; here we just copy to clipboard as fallback
    // But we can also call Navigator.pop with data and let parent share.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share: salin tautan (belum implement share langsung di widget)')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text(widget.place.name.isNotEmpty ? widget.place.name : widget.place.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                IconButton(
                  onPressed: _toggleSave,
                  icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_border),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.place.displayName, style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Lat: ${widget.place.lat.toStringAsFixed(6)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(width: 12),
                Text('Lon: ${widget.place.lon.toStringAsFixed(6)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openExternal,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Buka di OSM'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
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
