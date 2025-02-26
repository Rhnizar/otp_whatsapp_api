import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

void main() {
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

  /// Generate a random 6-digit OTP
  String _generateOTP() {
    final Random random = Random();
    return (100000 + random.nextInt(900000)).toString(); // 6-digit OTP
  }

    Future<void> _sendWhatsAppMessage() async {
    String phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedOTP = _generateOTP(); // Generate OTP dynamically
    });

    const String apiUrl =
        'https://graph.facebook.com/v22.0/555403124326299/messages';
    const String accessToken = 'EAAI0pKUvkRMBOyN0XnhPLHdidjfdyKD3oyXTnhFCy2JIL4XCC5OTxTaNu3GwOPRue8AidGuYRHefGZC1tKtPYqq3EdGn5dzPRPXzl9fm9AHQLPh5r8xO0aw0Ub07urzOkMdiU5yo18ONAFmZBKpR9DQcbkplRl63HWdf0YBD3peubo0M8XA9dsAhqQFeus7ZAgH5lTyterTdk2nm6NWe8sRjdoZD';

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
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Enter Phone Number',
                border: OutlineInputBorder(),
              ),
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

// 🔹 Page 2: Enter OTP
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
    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter OTP',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyOTP,
              child: const Text('Verify OTP'),
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
