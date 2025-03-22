import 'package:latlong2/latlong.dart';

class RouteResponse {
  final String polyline;
  final List<LatLng> decodedRoute;

  RouteResponse({
    required this.polyline,
    required this.decodedRoute,
  });

  /// Factory constructor to create an instance from a JSON map
  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    print(json["decodedRoute"]);
    return RouteResponse(
      polyline: json['polyline'],
      decodedRoute: (json['decodedRoute'] as List)
          .map((coords) => LatLng(coords[0] as double, coords[1] as double))
          .toList(),
    );
  }

  /// Converts the instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'polyline': polyline,
      'decodedRoute': decodedRoute
          .map((coords) => [coords.latitude, coords.longitude])
          .toList(),
    };
  }
}