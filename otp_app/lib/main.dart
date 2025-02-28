import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:pinput/pinput.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String get apiUrl => dotenv.env['API_URL'] ?? '';
  static String get accessToken => dotenv.env['ACCESS_TOKEN'] ?? '';
}
// decalre the variables globally
late final String apiUrl;
late final String accessToken;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "/home/rida/Desktop/otp_whatsapp_api/otp_app/.env"); // using an absolute path to the .env file
  apiUrl = Config.apiUrl;
  accessToken = Config.accessToken;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OTP Verification',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const OTPVerificationScreen(),
    );
  }
}

// 🔹 Page 1: OTP Verification (Send OTP)
class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key});

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _generatedOTP;
  String _fullPhoneNumber = '';

  /// Generate a random 6-digit OTP
  String _generateOTP() {
    final Random random = Random();
    return (100000 + random.nextInt(900000)).toString(); // 6-digit OTP
  }

    Future<void> _sendWhatsAppMessage() async {
    // String phoneNumber = _phoneController.text.trim();
    String phoneNumber = _fullPhoneNumber.trim();
    print('phone numberrrr  : ${phoneNumber}');
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number!')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // for load the UI 
      _generatedOTP = _generateOTP(); // Generate OTP dynamically
    });

    final Map<String, dynamic> requestBody = {
      "messaging_product": "whatsapp",
      "to": phoneNumber,
      "type": "template",
      "template": {
        "name": "otp2", // Your approved template name
        "language": {"code": "en"},
        "components": [
          {
            "type": "body",
            "parameters": [
              {"type": "text", "text": _generatedOTP} // Send dynamic OTP
            ]
          },
          {
            "type": "button",
            "sub_type": "url",
            "index": "0",
            "parameters": [
          {"type": "text", "text": _generatedOTP}
          ]
        }
        ]
      }
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print('Message sent successfully: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP Sent: $_generatedOTP')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                EnterOTPPage(otp: _generatedOTP!),
          ),
        );
      } else {
        print('Failed to send message: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message!')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OTP Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IntlPhoneField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Enter Phone Number',
                border: OutlineInputBorder(),
              ),
              initialCountryCode: 'US', // Default country code
              onChanged: (phone) {
              setState(() {
                _fullPhoneNumber = phone.completeNumber; // ✅ Save full number
              });
            },
              
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _sendWhatsAppMessage,
                    child: const Text('Send OTP'),
                  ),
          ],
        ),
      ),
    );
  }

}

class EnterOTPPage extends StatefulWidget {
  final String otp;
  const EnterOTPPage({super.key, required this.otp});

  @override
  _EnterOTPPageState createState() => _EnterOTPPageState();
}

class _EnterOTPPageState extends State<EnterOTPPage> {
  final TextEditingController _otpController = TextEditingController();
  int _attemptsLeft = 3;

  void _verifyOTP() {
    if (_otpController.text == widget.otp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP Verified Successfully!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
    } else {
      setState(() {
        _attemptsLeft--;
      });

      if (_attemptsLeft > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid OTP! You have $_attemptsLeft attempts left.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Too many failed attempts. Try again!')),
        );
        Navigator.pop(context); // Go back to Send OTP Page
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade700, width: 2),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Enter the 6-digit OTP sent to your phone",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),

            // ✅ Fixed OTP Input Field
            Pinput(
              controller: _otpController,
              length: 6,
              keyboardType: TextInputType.number,
              autofocus: true,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusedPinTheme,
              onCompleted: (value) {
                _verifyOTP();
              },
            ),

            const SizedBox(height: 30),

            // 🔹 Verify OTP Button
            ElevatedButton(
              onPressed: _verifyOTP,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Verify OTP'),
            ),

            const SizedBox(height: 20),

            // 🔹 Resend OTP Option
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Resending OTP...')),
                );
              },
              child: const Text(
                "Didn't receive OTP? Resend",
                style: TextStyle(fontSize: 16, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// 🔹 Page 3: Welcome Page
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: const Center(
        child: Text(
          '🎉 Welcome! You have successfully verified your OTP.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

