import 'dart:convert';
import 'package:bus_ticket_scanner/services/api_client.dart';

class ApiService {
  static Future<dynamic> validateTicket(String qrData, String token) async {
    final bookingId = json.decode(qrData)['bookingId'];
    final response = await ApiClient.put(
      '/api/bookings/mark/attended',
      data: {'bookingId': bookingId},
      token: token,
    );
    return response.data;
  }
}
