class RouteResponse {
  final String polyline;
  final List<List<double>> decodedRoute;

  RouteResponse({
    required this.polyline,
    required this.decodedRoute,
  });

  /// Factory constructor to create an instance from a JSON map
  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    return RouteResponse(
      polyline: json['polyline'],
      decodedRoute: (json['decodedRoute'] as List)
          .map((coords) => (coords as List).map((e) => (e as num).toDouble()).toList())
          .toList(),
    );
  }

  /// Converts the instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'polyline': polyline,
      'decodedRoute': decodedRoute.map((coords) => coords.map((e) => e).toList()).toList(),
    };
  }
}