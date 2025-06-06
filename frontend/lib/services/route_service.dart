import 'dart:convert';

import 'package:bussin_buses/models/RouteResponse.dart';
import 'package:http/http.dart' as http;

const String _host = "10.0.2.2:3000";
const String _basePath = "api";
const String _startJoruneyPath = "$_basePath/start-journey";
const String _stopJourneyPath = "$_basePath/stop-journey";
const String _getReroutePath = "$_basePath/get-reroute";
const String _calculateEtaPath = "$_basePath/get-eta";

/// RouteService contains all API calls to our custom routing server on NodeJS/Express
class RouteService {

  /// calls the /start-journey endpoint to signal driver is on trip and get route data to display
  Future<RouteResponse> startJourney(String driverId, String scheduleId) async {
    Uri url = Uri.http(_host, _startJoruneyPath);
    var response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "driver_id": driverId,
          "schedule_id": scheduleId
        }));
    // parse the JSON string into a Dart object
    var jsonResponse = jsonDecode(response.body);
    print(jsonResponse.toString());
    return RouteResponse.fromJson(jsonResponse);
  }

  /// calls /stop-journey endpoint to signal driver is not on trip anymore
  Future<int> stopJourney(String driverId, String scheduleId) async {
    Uri url = Uri.http(_host, _stopJourneyPath);
    var response = await http.post(url, headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "driver_id": driverId,
      "schedule_id": scheduleId
    }));

    Map<String, dynamic> res = jsonDecode(response.body);
    String message = res["message"];
    print(res);
    print(message);

    if (message == "Journey stopped successfully") {
      return 0;
    }
    else {
      return -1;
    }
  }

  /// calls /get-eta endpoint to update the ETA
  Future<void> calculateETA(String driverId, String scheduleId) async {
    Uri url = Uri.http(_host, _calculateEtaPath);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driver_id': driverId,
          'schedule_id': scheduleId,
        }),
      );

      if (response.statusCode != 200) {
        print("Failed to calculate ETA. Status: ${response.statusCode}, Body: ${response.body}");
      } else {
        print("ETA calculated and stored successfully.");
      }
    } catch (e) {
      print("Error calling calculateETA: $e");
    }
  }

  /// calls /get-reroute endpoint to get new polyline and ETA
  Future<RouteResponse> getReroute(String driverId) async {
    Uri uri = Uri.http(_host, _getReroutePath, {
      "driverId": driverId
    });
    final response = await http.get(uri, headers: {"Content-Type": "application/json"});
    final parsedResponse = jsonDecode(response.body);
    print(parsedResponse.toString());
    return RouteResponse.fromJson(parsedResponse);
  }
}