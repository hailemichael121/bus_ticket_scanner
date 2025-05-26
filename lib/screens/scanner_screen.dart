import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:bus_ticket_scanner/models/ticket.dart';
import 'package:bus_ticket_scanner/screens/ticket_detail_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal, // Faster detection
    facing: CameraFacing.back,
    torchEnabled: false,
    formats: [BarcodeFormat.qrCode],
  );

  final Logger _logger = Logger();
  final Dio _dio = Dio();
  bool _isProcessing = false;
  bool _hasPermission = false;
  Timer? _scanCooldownTimer;
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  int _scanAttempts = 0;

  @override
  void initState() {
    super.initState();
    _logger.i('Scanner screen initialized');
    _checkPermissions();
    _setupDio();
  }

  void _setupDio() {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    );
    _dio.interceptors.add(LogInterceptor(
      request: true,
      responseBody: true,
      error: true,
    ));
  }

  Future<void> _checkPermissions() async {
    _logger.i('Checking camera permissions');
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _logger.i('Camera permission granted');
      setState(() => _hasPermission = true);
    } else {
      _logger.w('Camera permission denied');
      setState(() => _hasPermission = false);
    }
  }

  void _handleAutoDetect(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty || _isProcessing) return;

    final barcode = capture.barcodes.first;
    final code = barcode.rawValue;

    if (code == null || code == _lastScannedCode) {
      _logger.d('Duplicate or empty QR code detected');
      return;
    }

    // Prevent rapid successive scans
    if (_lastScanTime != null &&
        DateTime.now().difference(_lastScanTime!) <
            const Duration(seconds: 1)) {
      _logger.d('Too frequent scans - ignoring');
      return;
    }

    _lastScannedCode = code;
    _lastScanTime = DateTime.now();
    _scanAttempts++;

    _logger.i('Auto-detected QR code (attempt $_scanAttempts)');
    _processQRCode(code);
  }

  Future<void> _processQRCode(String rawValue) async {
    if (_isProcessing) {
      _logger.d('Already processing a QR code - skipping');
      return;
    }

    _logger.i('Starting QR processing');
    setState(() => _isProcessing = true);

    try {
      _logger.d('Raw QR data: $rawValue');

      if (!rawValue.startsWith('{')) {
        throw FormatException('Invalid QR format - does not contain JSON data');
      }

      final decoded = jsonDecode(rawValue);
      _logger.d('Successfully decoded QR data');

      final ticket = Ticket.fromJson(decoded);
      _logger.i('Created ticket with ID: ${ticket.bookingId}');

      // Start cooldown timer to prevent immediate re-scan
      _startScanCooldown();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TicketDetailScreen(
            ticket: ticket,
            initialStatus: ticket.isAttended
                ? TicketStatus.alreadyAttended
                : TicketStatus.pending,
          ),
        ),
      );

      _logger.i('Navigated to ticket details');
    } on FormatException catch (e) {
      _logger.e('Invalid QR format', error: e);
      _showToast('Invalid ticket format');
    } catch (e) {
      _logger.e('QR processing failed', error: e);
      _showToast('Failed to process QR code');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _startScanCooldown() {
    _scanCooldownTimer?.cancel();
    _scanCooldownTimer = Timer(const Duration(seconds: 2), () {
      _lastScannedCode = null;
      _logger.d('Scan cooldown ended - ready for new scans');
    });
  }

  Future<void> _scanFromGallery() async {
    if (_isProcessing) {
      _showToast('Please wait for current scan to complete');
      return;
    }

    _logger.i('Starting gallery scan');
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        _logger.d('No image selected');
        return;
      }

      _logger.d('Image selected from gallery');
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop QR Code',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop QR Code',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile == null) {
        _logger.d('Image cropping cancelled');
        return;
      }

      _logger.d('Image cropped successfully');
      final success = await _controller.analyzeImage(croppedFile.path);
      if (success) {
        _logger.i('Image analysis started');
        await for (final capture in _controller.barcodes) {
          if (capture.barcodes.isNotEmpty) {
            final barcode = capture.barcodes.first;
            if (barcode.rawValue != null) {
              _logger.i('QR code found in image');
              await _processQRCode(barcode.rawValue!);
              break;
            }
          }
        }
      }
    } catch (e) {
      _logger.e('Gallery scan failed', error: e);
      _showToast('Error scanning image');
    }
  }

  void _showToast(String message) {
    _logger.d('Showing toast: $message');
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _logger.i('Scanner screen disposed');
    _scanCooldownTimer?.cancel();
    _controller.dispose();
    _dio.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text('Permissions Required')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  'Camera permission is required to scan tickets',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text('Open Settings'),
                  onPressed: openAppSettings,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Ticket'),
        // Removed torch button from app bar
        actions: [],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleAutoDetect,
          ),
          _buildScannerOverlay(),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: 'gallery',
                  onPressed: _isProcessing ? null : _scanFromGallery,
                  tooltip: 'Scan from Gallery',
                  child: const Icon(Icons.photo_library),
                ),
                // Fancy torch button with animation
                ValueListenableBuilder(
                  valueListenable: _controller.torchState,
                  builder: (context, state, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (state == TorchState.on)
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.8),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                        ],
                      ),
                      child: FloatingActionButton(
                        heroTag: 'torch',
                        onPressed: () => _controller.toggleTorch(),
                        tooltip: 'Toggle Flash',
                        backgroundColor: state == TorchState.on
                            ? Colors.amber
                            : Theme.of(context).primaryColor,
                        child: Icon(
                          state == TorchState.on
                              ? Icons.flashlight_on_rounded
                              : Icons.flashlight_off_rounded,
                          color: state == TorchState.on
                              ? Colors.black
                              : Colors.white,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
                FloatingActionButton(
                  heroTag: 'focus',
                  onPressed: () => _controller.start(),
                  tooltip: 'Auto Focus',
                  child: const Icon(Icons.center_focus_strong),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(
            color: _isProcessing
                ? Colors.blue
                : Theme.of(context).primaryColor.withOpacity(0.8),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _isProcessing
            ? const Center(
                child: Icon(
                  Icons.check_circle,
                  color: Colors.blue,
                  size: 60,
                ),
              )
            : null,
      ),
    );
  }
}
