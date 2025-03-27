import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User? _currentUser;
  String _rollNumber = "Loading...";
  String _name = "Loading...";
  String _degree = "Loading...";
  String _email = "Loading...";
  int _userBalance = 0;
  double _creatorBalance = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_currentUser != null) {
      try {
        QuerySnapshot querySnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: _currentUser!.email)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          DocumentSnapshot userDoc = querySnapshot.docs.first;
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _rollNumber = userData['rollNumber'] ?? 'No roll number found';
            _name = userData['name'] ?? 'No name found';
            _degree = userData['degree'] ?? 'No degree found';
            _email = userData['email'] ?? 'No email found';
            _userBalance = userData['user_balance'] ?? 0;
            _creatorBalance = userData['creator_balance']?.toDouble() ?? 0.0;
            _isLoading = false;
          });
        } else {
          setState(() {
            _rollNumber = 'User data not found';
            _name = 'User data not found';
            _degree = 'User data not found';
            _email = 'User data not found';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _rollNumber = 'Error loading data';
          _name = 'Error loading data';
          _degree = 'Error loading data';
          _email = 'Error loading data';
          _isLoading = false;
        });
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Profile Page',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Information',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                      Icons.confirmation_number,
                      Colors.purple,
                      'Roll Number',
                      _rollNumber
                  ),
                  _buildInfoRow(
                      Icons.person,
                      Colors.blue,
                      'Name',
                      _name
                  ),
                  _buildInfoRow(
                      Icons.school,
                      Colors.orange,
                      'Degree',
                      _degree
                  ),
                  _buildInfoRow(
                      Icons.email,
                      Colors.green,
                      'Email',
                      _email
                  ),
                  _buildInfoRow(
                      Icons.account_balance_wallet,
                      Colors.teal,
                      'User Balance',
                      _userBalance.toString()
                  ),
                  _buildInfoRow(
                      Icons.monetization_on,
                      Colors.brown,
                      'Creator Balance',
                      _creatorBalance.toStringAsFixed(2)
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: Colors.blue.shade100,
          labelTextStyle: MaterialStateProperty.all(
            GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        child: NavigationBar(
          selectedIndex: 2,
          onDestinationSelected: (index) {
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/home');
            } else if (index == 1) {
              Navigator.pushReplacementNamed(context, '/history');
            } else if (index == 2) {
              Navigator.pushReplacementNamed(context, '/profile');
            } else if (index == 3) {
              Navigator.pushReplacementNamed(context, '/create-screen');
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle),
              label: 'Create',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, Color iconColor, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}