import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  // Initialize GoogleSignIn with required scopes.
  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/forms.responses.readonly',
    ],
    // Optionally, specify your clientId if needed:
    clientId: '926968766088-0f0hopunn7mhdj5elot8eak1tgo8n2ks.apps.googleusercontent.com',
  );

  // Attempt to sign in silently; if not, trigger interactive sign-in.
  GoogleSignInAccount? account = await googleSignIn.signInSilently() ?? await googleSignIn.signIn();
  if (account == null) {
    print('Google Sign-In failed.');
    return;
  }

  final auth = await account.authentication;
  final String? accessToken = auth.accessToken;
  if (accessToken == null) {
    print('Could not obtain access token.');
    return;
  }

  // Use the same form ID as before.
  final String formId = '1FAIpQLSfRxPaDtBzNc0mQxjZU9QAfuEwupih1Dbvf2s5DUS1OrqJB5A';
  final url = Uri.parse('https://forms.googleapis.com/v1/forms/$formId/responses');
  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $accessToken',
    },
  );

  if (response.statusCode == 200) {
    final responses = json.decode(response.body);
    print('Form Responses:');
    print(const JsonEncoder.withIndent('  ').convert(responses));
  } else {
    print('Error fetching responses: ${response.body}');
  }
}
