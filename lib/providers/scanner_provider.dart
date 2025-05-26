import 'dart:async';
import 'dart:convert';
import 'package:bus_ticket_scanner/providers/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:bus_ticket_scanner/models/ticket.dart';
import 'package:bus_ticket_scanner/api/api_service.dart';
import 'package:provider/provider.dart';

class ScannerProvider with ChangeNotifier {
  Ticket? _scannedTicket;
  bool _isLoading = false;
  String? _error;

  Ticket? get scannedTicket => _scannedTicket;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> scanTicket(
      String qrData, String token, BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Optional: Validate QR structure
      final decodedData = jsonDecode(qrData);
      if (decodedData is! Map || !decodedData.containsKey('bookingId')) {
        throw FormatException('Invalid QR data format');
      }

      final response = await ApiService.validateTicket(qrData, token);
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final ticket = Ticket.fromJson(data);
        ticket.isValid = data['Is_Valid'] ?? true;

        final historyProvider =
            Provider.of<HistoryProvider>(context, listen: false);
        await historyProvider.loadScans();
        await historyProvider.addScan(ticket);

        _scannedTicket = ticket;
      } else {
        _handleApiError(data);
        return;
      }
    } on FormatException {
      _error = 'Scanned code is not a valid bus ticket QR.';
      showErrorSnackbar(context, _error!);
      _scannedTicket = Ticket.invalidWithError(_error!);
    } catch (e) {
      _handleError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleApiError(Map<String, dynamic> errorData) {
    final errorMessage = errorData['message'] ?? 'Ticket validation failed';
    final errorDetails = errorData['details'] ?? 'Unknown error occurred';

    _error = '$errorMessage\n$errorDetails';

    // Create an invalid ticket with error details
    _scannedTicket = Ticket(
      bookingId: 'INVALID',
      busNumber: 'INVALID',
      paymentReference: 'INVALID',
      fullPaymentInfo: {
        'error': errorMessage,
        'details': errorDetails,
      },
      route: 'INVALID',
      seats: [0],
      departureTime: DateTime.now(),
      arrivalTime: DateTime.now(),
      isValid: false,
    );
  }

  void _handleError(dynamic error) {
    if (error is FormatException) {
      _error =
          'Invalid QR code format. Please scan a valid bus ticket QR code.';
    } else if (error is TimeoutException) {
      _error = 'Request timed out. Please check your internet connection.';
    } else if (error is TypeError) {
      _error = 'Data format error. Please try again.';
    } else {
      _error = 'An unexpected error occurred: ${error.toString()}';
    }

    // Create an invalid ticket with error details
    _scannedTicket = Ticket(
      bookingId: 'ERROR',
      busNumber: 'ERROR',
      paymentReference: 'ERROR',
      fullPaymentInfo: {
        'error': _error,
      },
      route: 'ERROR',
      seats: [0],
      departureTime: DateTime.now(),
      arrivalTime: DateTime.now(),
      isValid: false,
    );
  }

  void setScannedTicket(Ticket ticket) {
    _scannedTicket = ticket;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void clearScan() {
    _scannedTicket = null;
    _error = null;
    notifyListeners();
  }

  void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void clearScannedTicket() {
    _scannedTicket = null;
    notifyListeners();
  }
}
