import 'dart:convert';

import 'package:bussin_buses/models/RouteResponse.dart';
import 'package:http/http.dart' as http;

const String _host = "10.0.2.2:3000";
const String _basePath = "api";
const String _startJoruneyPath = "$_basePath/start-journey";
const String _stopJourneyPath = "$_basePath/stop-journey";

class RouteService {
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

  Future<int> stopJourney(String driverId, String scheduleId) async {
    Uri url = Uri.http(_host, _stopJourneyPath);
    var response = await http.post(url, headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "driver_id": driverId,
      "schedule_id": scheduleId
    }));

    Map<String, dynamic> res = jsonDecode(response.body);
    String message = res["message"];
    if (message == "Journey stopped successfully") {
      return 0;
    }
    else {
      print(message);
      return -1;
    }

  }
}