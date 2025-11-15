import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HiveMapPage extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String hiveName;

  const HiveMapPage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.hiveName,
  });

  @override
  Widget build(BuildContext context) {
    final hivePosition = LatLng(latitude, longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text("موقع ${hiveName}"),
        backgroundColor: Colors.orange,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: hivePosition,
          zoom: 16,
        ),
        markers: {
          Marker(
            markerId: MarkerId("hive"),
            position: hivePosition,
            infoWindow: InfoWindow(title: hiveName),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          )
        },
        mapType: MapType.hybrid,
      ),
    );
  }
}
