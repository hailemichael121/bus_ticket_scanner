import 'dart:convert';
import 'package:intl/intl.dart';

class Ticket {
  final String bookingId;
  final String busNumber;
  final String paymentReference;
  final Map<String, dynamic> fullPaymentInfo;
  final String route;
  final List<int> seats;
  final DateTime departureTime;
  final DateTime arrivalTime;
  bool isValid;
  bool isAttended;
  final DateTime scanTime;

  Ticket({
    required this.bookingId,
    required this.busNumber,
    required this.paymentReference,
    required this.fullPaymentInfo,
    required this.route,
    required this.seats,
    required this.departureTime,
    required this.arrivalTime,
    this.isValid = false,
    this.isAttended = false,
    DateTime? scanTime,
  }) : scanTime = scanTime ?? DateTime.now();

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      bookingId: json['Booking_ID'] ?? '',
      busNumber: json['Bus_Number'] ?? '',
      paymentReference: json['Payment_Reference'] ?? '',
      fullPaymentInfo: json['Full_Payment_Info'] is String
          ? jsonDecode(json['Full_Payment_Info'])
          : json['Full_Payment_Info'] ?? {},
      route: json['Route'] ?? '',
      seats: (json['Seat'] is List
          ? List<int>.from(json['Seat'])
          : [json['Seat'] ?? 0]),
      departureTime: DateTime.parse(json['Departure_Time']),
      arrivalTime: DateTime.parse(json['Arrival_Time']),
      isValid: json['Is_Valid'] ?? true,
      isAttended: json['Is_Attended'] ?? false,
      scanTime:
          json['scanTime'] != null ? DateTime.parse(json['scanTime']) : null,
    );
  }

  factory Ticket.invalidWithError(String error) => Ticket(
        bookingId: 'INVALID',
        busNumber: 'INVALID',
        paymentReference: 'INVALID',
        fullPaymentInfo: {'error': error},
        route: error,
        seats: [],
        departureTime: DateTime.now(),
        arrivalTime: DateTime.now(),
        isValid: false,
        isAttended: false,
      );

  String get formattedDate => DateFormat('MMM dd, yyyy').format(scanTime);
  String get formattedDepartureTime =>
      DateFormat('hh:mm a, MMM dd').format(departureTime);
  String get formattedArrivalTime =>
      DateFormat('hh:mm a, MMM dd').format(arrivalTime);
  String get formattedRoute => route.replaceAll(' to ', ' → ');
  String get formattedSeat => seats.map((s) => 'Seat $s').join(', ');
  String get formattedBusNumber => busNumber;
  String get formattedBookingId => bookingId;
  String get formattedPaymentReference => paymentReference;

  String get formattedFullPaymentInfo {
    final info = fullPaymentInfo;
    return '''
Name: ${info['first_name']} ${info['last_name'] ?? ''}
Email: ${info['email'] ?? 'N/A'}
Amount: ${info['amount']} ${info['currency']}
Status: ${info['status']?.toString().toUpperCase() ?? 'N/A'}
Reference: ${info['reference'] ?? 'N/A'}
Date: ${info['created_at'] != null ? DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.parse(info['created_at'])) : 'N/A'}
''';
  }

  String get formattedTime => DateFormat('hh:mm a').format(scanTime);
  String get formattedScanDate => DateFormat('MMM dd, yyyy').format(scanTime);

  Map<String, dynamic> toJson() => {
        'Booking_ID': bookingId,
        'Bus_Number': busNumber,
        'Payment_Reference': paymentReference,
        'Full_Payment_Info': jsonEncode(fullPaymentInfo),
        'Route': route,
        'Seat': seats,
        'Departure_Time': departureTime.toIso8601String(),
        'Arrival_Time': arrivalTime.toIso8601String(),
        'Is_Valid': isValid,
        'Is_Attended': isAttended,
        'scanTime': scanTime.toIso8601String(),
      };
}
