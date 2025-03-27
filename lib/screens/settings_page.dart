import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

/// This SettingsPage fetches and displays the Google Form JSON from the API
/// and automatically refreshes the response every 1 minute.
class _SettingsPageState extends State<SettingsPage> {
  String _responseJson = '';
  bool _loading = true;
  String _error = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Fetch the JSON immediately when the page loads.
    fetchFormJson();
    // Set up a timer to refresh the JSON every 1 minute.
    _timer = Timer.periodic(const Duration(minutes: 1), (Timer t) {
      fetchFormJson();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Fetches the form JSON from the Google Forms API.
  Future<void> fetchFormJson() async {
    final url = Uri.parse(
        'https://forms.googleapis.com/v1/forms/1cGVPBCC-Z_1piiX2TrxdCFsv-czn3IR6E9dZmEeYFZg');

    final headers = {
      'Authorization': 'Bearer ya29.a0AeXRPp5hBOFaBKKd5IlYEMU-u48YrJvTjLLX7FIM4M0GS2WaIinIIf_ROLLR7rY5HR7q071DJb8bCtxbIbnInV3jnShN9ZJ4h2pmSGovjKYVUDM-FtO72HKPdLvL-IHAFnz34qA6l01cSlLYxoHVwVISUnhTh6BXUDQrfr4WaCgYKAUUSARISFQHGX2MiXVw8UXah9SBj7RJVy46w-A0175',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        setState(() {
          _responseJson =
              const JsonEncoder.withIndent('  ').convert(json.decode(response.body));
          _loading = false;
          _error = '';
        });
      } else {
        setState(() {
          _error =
          'Error: ${response.statusCode} ${response.reasonPhrase}\n${response.body}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  Widget buildBottomNavigation(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Create'),
      ],
      currentIndex: 3,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (index == 1) {
          Navigator.pushReplacementNamed(context, '/history');
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, '/profile');
        } else if (index == 3) {
          // Already on SettingsPage.
        } else if (index == 4) {
          Navigator.pushReplacementNamed(context, '/create-screen');
        }
      },
      type: BottomNavigationBarType.fixed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings Page'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
            ? Text(
          _error,
          style: const TextStyle(color: Colors.red),
        )
            : SingleChildScrollView(
          child: Text(
            _responseJson,
            style: const TextStyle(fontFamily: 'Courier'),
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNavigation(context),
    );
  }
}
