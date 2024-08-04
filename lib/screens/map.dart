import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/place.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({
    super.key,
    this.location = const PlaceLocation(
      latitude: 65.01236,
      longitude: 25.46816,
      address: '',
    ),
    this.isSelecting = true,
  });

  final PlaceLocation location;
  final bool isSelecting;

  @override
  ConsumerState<MapScreen> createState() {
    return _MapScreenState();
  }
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  LatLng? _pickedLocation;
  LatLng? _currentLocation;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  final List<Color> _colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.yellow,
  ];
  Color _currentColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _startRandomColorAnimation();
        }
      });
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize with a default animation to avoid late initialization error
    _colorAnimation = ColorTween(begin: _currentColor, end: _currentColor)
        .animate(_animationController);
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<bool> _handleLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  void _selectLocation(dynamic tapPosn, LatLng posn) {
    setState(() {
      _pickedLocation = posn;
    });
    _startRandomColorAnimation();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location selected: ${posn.latitude}, ${posn.longitude}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _startRandomColorAnimation() {
    final randomIndex =
        (DateTime.now().millisecondsSinceEpoch % _colors.length).toInt();
    _currentColor = _colors[randomIndex];
    _colorAnimation = ColorTween(begin: _currentColor, end: _randomColor())
        .animate(_animationController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.reverse();
        }
      });

    _animationController.forward();
  }

  Color _randomColor() {
    final randomIndex =
        (DateTime.now().millisecondsSinceEpoch % _colors.length).toInt();
    return _colors[randomIndex];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.isSelecting ? 'Pick your Location' : 'Your Location'),
        actions: [
          if (widget.isSelecting)
            InkWell(
              onTap: () {
                _animationController.stop();
                Navigator.of(context).pop(_pickedLocation);
              },
              child: AnimatedBuilder(
                animation: _colorAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Icon(
                      Icons.save,
                      color: _colorAnimation.value,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _currentLocation ??
              LatLng(widget.location.latitude, widget.location.longitude),
          initialZoom: 10,
          onTap: widget.isSelecting ? _selectLocation : null,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://{s}.google.com/vt/lyrs=m&hl={hl}&x={x}&y={y}&z={z}',
            additionalOptions: const {'hl': 'en'},
            subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
            maxZoom: 19,
          ),
          if (_pickedLocation != null || _currentLocation !=null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _pickedLocation ?? _currentLocation ??
                      LatLng(
                          widget.location.latitude, widget.location.longitude),
                  child: const Icon(
                    Icons.pin_drop,
                    size: 30,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
