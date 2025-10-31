// lib/screens/screen_tugas_maps.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_news_app/models/place.dart';
import 'package:flutter_news_app/services/geocode_service.dart';
import 'package:flutter_news_app/services/location_service.dart';
import 'package:flutter_news_app/widgets/map_marker_info.dart';
import 'package:flutter_news_app/widgets/map_search_suggestions.dart';

class ScreenTugasMaps extends StatefulWidget {
  const ScreenTugasMaps({super.key});

  @override
  State<ScreenTugasMaps> createState() => _ScreenTugasMapsState();
}

class _ScreenTugasMapsState extends State<ScreenTugasMaps> {
  // Controllers & services
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  final GeocodeService _geocode = GeocodeService();
  final LocationService _locationService = LocationService();

  // State
  List<Place> _suggestions = <Place>[];
  bool _searchLoading = false;
  String _query = '';
  final List<Place> _markers = <Place>[];

  bool _loadingFavorites = true;
  List<Place> _favorites = <Place>[];

  // Map constants
  static const LatLng _initialCenter = LatLng(-6.200000, 106.816666);
  static const double _initialZoom = 5;
  static const double _minZoom = 3;
  static const double _maxZoom = 18;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _loadFavorites() async {
    setState(() => _loadingFavorites = true);

    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList('maps_favorites') ?? <String>[];

    final list = raw.map((s) {
      try {
        final m = json.decode(s) as Map<String, dynamic>;
        return Place.fromJson(m);
      } catch (_) {
        return null;
      }
    }).whereType<Place>().toList();

    if (!mounted) return;
    setState(() {
      _favorites = list;
      _loadingFavorites = false;
    });
  }

  Future<void> _onSearchChanged(String text) async {
    setState(() => _query = text);

    if (text.trim().isEmpty) {
      setState(() {
        _suggestions = <Place>[];
        _searchLoading = false;
      });
      return;
    }

    setState(() => _searchLoading = true);
    try {
      final res = await _geocode.search(text.trim(), limit: 6);
      if (!mounted) return;
      setState(() {
        _suggestions = res;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _suggestions = <Place>[];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search error: $e')),
      );
    } finally {
      // 👉 jangan return di finally (menghindari control_flow_in_finally)
      if (mounted) {
        setState(() => _searchLoading = false);
      }
    }
  }

  void _addMarker(Place p, {bool center = true, bool openSheet = true}) {
    final exists = _markers.any((m) => m.id == p.id);
    if (!exists) {
      setState(() {
        _markers.add(p);
      });
    }
    if (center) {
      _mapController.move(LatLng(p.lat, p.lon), 15);
    }
    if (openSheet) {
      _showPlaceBottomSheet(p);
    }
  }

  Future<void> _showPlaceBottomSheet(Place p) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => MapMarkerInfo(
        place: p,
        onSavedChanged: _loadFavorites,
      ),
    );
  }

  Future<void> _centerToMyLocation() async {
    try {
      final pos = await _locationService.getCurrentPosition();
      if (!mounted) return;

      _mapController.move(LatLng(pos.latitude, pos.longitude), 15);

      final place = Place(
        id:
            '${pos.latitude.toStringAsFixed(6)},${pos.longitude.toStringAsFixed(6)}',
        name: 'Lokasi Anda',
        displayName:
            'Lat ${pos.latitude.toStringAsFixed(6)}, Lon ${pos.longitude.toStringAsFixed(6)}',
        lat: pos.latitude,
        lon: pos.longitude,
      );
      _addMarker(place, center: false, openSheet: false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pusat ke lokasi Anda')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendapatkan lokasi: $e')),
      );
    }
  }

  Future<void> _openFavoritesSheet() async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        if (_loadingFavorites) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (_favorites.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text('Belum ada favorite. Simpan lokasi dari marker.'),
            ),
          );
        }

        // ✅ SafeArea harus pakai child:, bukan builder:
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _favorites.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final f = _favorites[index];
                return ListTile(
                  leading: const Icon(Icons.place),
                  title: Text(f.name.isNotEmpty ? f.name : f.displayName),
                  subtitle: Text(
                    f.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _addMarker(f, center: true);
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () async {
                      final sp = await SharedPreferences.getInstance();
                      final raw =
                          sp.getStringList('maps_favorites') ?? <String>[];
                      raw.removeWhere((s) {
                        try {
                          final m = json.decode(s) as Map<String, dynamic>;
                          return m['id'] == f.id;
                        } catch (_) {
                          return false;
                        }
                      });
                      await sp.setStringList('maps_favorites', raw);

                      if (!mounted) return;
                      await _loadFavorites();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dihapus dari favorites')),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    await _loadFavorites();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final markersLayer = _markers
    .map(
      (p) => Marker(
        point: LatLng(p.lat, p.lon),
        width: 42,
        height: 42,
        child: GestureDetector(
          onTap: () => _showPlaceBottomSheet(p),
          child: const Icon(
            Icons.location_on,
            size: 42,
            color: Colors.redAccent,
          ),
        ),
      ),
    )
    .toList();


    return Scaffold(
      appBar: AppBar(
        title: const Text('Tugas 2 — Maps (OSM)'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _loadFavorites, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: _openFavoritesSheet,
            icon: const Icon(Icons.bookmarks),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              // ✅ v8+: gunakan initialCenter & initialZoom
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
              minZoom: _minZoom,
              maxZoom: _maxZoom,

              // ✅ Gestur lengkap + inertia (rotasi dimatikan)
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.pinchMove |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.scrollWheelZoom |
                    InteractiveFlag.flingAnimation &
                        ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // Hapus 'const' di sini agar tidak memicu const_with_non_const
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dev.flutter.newsapp',
              ),
              MarkerLayer(markers: markersLayer),
            ],
          ),

          // Attribution
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.85),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ),

          // Search bar + suggestions
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.06),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: _onSearchChanged,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (v) async {
                              if (_suggestions.isNotEmpty) {
                                _addMarker(_suggestions.first);
                                _searchCtrl.clear();
                                setState(() => _suggestions = <Place>[]);
                              } else {
                                await _onSearchChanged(v);
                                if (!mounted) return;
                                if (_suggestions.isNotEmpty) {
                                  _addMarker(_suggestions.first);
                                }
                              }
                            },
                            decoration: InputDecoration(
                              hintText:
                                  'Cari lokasi (contoh: Monas, Mall, Stasiun)...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() {
                                          _suggestions = <Place>[];
                                          _query = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        heroTag: 'loc_btn',
                        mini: true,
                        onPressed: _centerToMyLocation,
                        child: const Icon(Icons.my_location),
                      ),
                    ],
                  ),

                  if (_query.isNotEmpty)
                    MapSearchSuggestions(
                      suggestions: _suggestions,
                      onPlaceSelected: (p) {
                        _addMarker(p);
                        _searchCtrl.clear();
                        setState(() => _suggestions = <Place>[]);
                      },
                      loading: _searchLoading,
                      query: _query,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Floating buttons
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'fav_btn',
            mini: true,
            onPressed: _openFavoritesSheet,
            child: const Icon(Icons.bookmark),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoom_in',
            mini: true,
            onPressed: () {
              final currentZoom = _mapController.camera.zoom;
              final center = _mapController.camera.center;
              final nextZoom = (currentZoom + 1).clamp(_minZoom, _maxZoom);
              _mapController.move(center, nextZoom);
            },
            child: const Icon(Icons.zoom_in),
          ),
        ],
      ),
    );
  }
}
