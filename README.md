# 🚌 Aggregated Bus Ticketing System

A sleek, production-ready Flutter solution for validating and managing bus tickets using real-time QR code scanning.

![App Banner](docs/banner.png)

---

## 🚀 Features

### 🎯 Core Functionality

* ✅ Real-time QR code scanning via device camera and gallery
* ✅ Instant ticket validation through API
* ✅ Offline scan history with local fallback
* ✅ Flashlight toggle, camera switch & gallery scan support
* ✅ Visual feedback for valid/invalid tickets
* ✅ Live ticket info screen with manual retry

### 🧰 Technical Stack

* 🛠 **Flutter 3.19+**
* 📦 **Provider** for state management
* 📸 **mobile\_scanner** for QR scanning
* 🔐 Secure API communication with error handling
* 🎨 Polished UI with custom themes & transitions
* 🌐 Works offline with smart cache fallback

---

## 📱 Screenshots

| Scanner                              | Ticket Detail                      | Scan History                         |
| ------------------------------------ | ---------------------------------- | ------------------------------------ |
| ![Scanner](docs/screens/scanner.png) | ![Ticket](docs/screens/ticket.png) | ![History](docs/screens/history.png) |

---

## ⚙️ Installation

Clone the repo and run:

```bash
git clone https://github.com/yourusername/bus-ticket-scanner.git
cd bus-ticket-scanner
flutter pub get
flutter run
```

Ensure you have a connected device or emulator running.

---

## 🔌 API Integration

**Endpoint:**

```http
POST /api/tickets/validate
```

**Headers:**

```
Content-Type: application/json
```

**Request Body:**

```json
{
  "ticketId": "BUS-12345",
  "validatorId": "OP-001"
}
```

**Response (success):**

```json
{
  "success": true,
  "ticket": {
    "id": "BUS-12345",
    "event": "City Express",
    "passenger": "John Doe",
    "validUntil": "2025-06-01T18:00:00Z"
  }
}
```

**Response (invalid):**

```json
{
  "success": false,
  "message": "Ticket not found or already used"
}
```

---

## 🗂 Project Structure

```
lib/
├── models/         # Ticket model and data structures
├── providers/      # Auth and scanner state logic
├── screens/        # UI screens (Auth, Scanner, Ticket Detail, History)
├── services/       # API and local storage services
├── widgets/        # Reusable components (buttons, overlays, dialogs)
└── theme/          # App-wide styles and color schemes
```

---

## ✅ Usage Flow

1. **Login** with your credentials
2. **Scan** ticket QR using camera or gallery
3. **View ticket details** and validation status
4. **Manual retry** if network fails
5. **Access history** of scanned tickets anytime

---

## 🛡 License

This project is licensed under the [MIT License](LICENSE).

---

## 👨‍💼 Developer Notes

* Optimized for mobile (Android & iOS)
* Tested on physical devices and emulators
* Error messages are user-friendly and localized
* Built with modularity and scalability in mind

---

## 📬 Feedback & Contributions

Feel free to [open an issue](https://github.com/yourusername/bus-ticket-scanner/issues) or submit a pull request. We'd love to improve this with the community!

---

> *Built with Flutter 💙 for seamless offline-first ticket validation*
