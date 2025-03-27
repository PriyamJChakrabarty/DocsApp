import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class NewSurvey extends StatefulWidget {
  const NewSurvey({super.key});
  @override
  State<NewSurvey> createState() => _NewSurveyState();
}

class _NewSurveyState extends State<NewSurvey> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController urlController = TextEditingController();
  final TextEditingController maxRespondentsController = TextEditingController();
  final TextEditingController numQuestionsController = TextEditingController();
  final TextEditingController payoutController = TextEditingController();

  DateTime? selectedDeadline;
  final TextEditingController deadlineController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    urlController.dispose();
    maxRespondentsController.dispose();
    deadlineController.dispose();
    numQuestionsController.dispose();
    payoutController.dispose();
    super.dispose();
  }

  Future<void> pickDeadlineDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Cannot select past dates
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        selectedDeadline = picked;
        deadlineController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a survey title';
    }
    if (value.trim().length < 5) {
      return 'Title must be at least 5 characters long';
    }
    if (value.trim().length > 100) {
      return 'Title cannot exceed 100 characters';
    }
    return null;
  }

  String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a Google Forms URL';
    }
    final urlRegex = RegExp(r'^https://docs\.google\.com/forms/.*$');
    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid Google Forms URL';
    }
    return null;
  }

  String? validateMaxRespondents(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter max respondents';
    }
    // Check if value is a valid integer
    final int? respondents = int.tryParse(value.trim());
    if (respondents == null) {
      return 'Max Respondents must be a whole number';
    }
    // Additional constraints
    if (respondents <= 0) {
      return 'Max Respondents must be greater than zero';
    }
    if (respondents > 1000) {
      return 'Max Respondents cannot exceed 1000';
    }
    return null;
  }

  String? validateNumQuestions(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter number of questions';
    }
    // Check if value is a valid integer
    final int? questions = int.tryParse(value.trim());
    if (questions == null) {
      return 'Number of Questions must be a whole number';
    }
    // Additional constraints
    if (questions <= 0) {
      return 'Number of Questions must be greater than zero';
    }
    if (questions > 100) {
      return 'Number of Questions cannot exceed 100';
    }
    return null;
  }

  String? validatePayout(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter payout amount';
    }
    // Check if value is a valid double
    final double? payout = double.tryParse(value.trim());
    if (payout == null) {
      return 'Payout must be a number';
    }
    // Additional constraints
    if (payout <= 0) {
      return 'Payout must be greater than zero';
    }
    if (payout > 100) {
      return 'Payout cannot exceed \$100 per respondent';
    }
    // Limit to two decimal places
    if ((payout * 100) % 1 != 0) {
      return 'Payout can only have up to 2 decimal places';
    }
    return null;
  }

  String? validateDeadline(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a deadline';
    }
    if (selectedDeadline == null) {
      return 'Invalid deadline selected';
    }
    // Ensure deadline is in the future
    if (selectedDeadline!.isBefore(DateTime.now())) {
      return 'Deadline must be in the future';
    }
    // Optional: Limit deadline to within 6 months
    final sixMonthsFromNow = DateTime.now().add(const Duration(days: 180));
    if (selectedDeadline!.isAfter(sixMonthsFromNow)) {
      return 'Deadline cannot be more than 6 months from now';
    }
    return null;
  }

  Future<void> saveSurveyToFirestore() async {
    String status = "ENQUEUE";
    int maxResp = int.parse(maxRespondentsController.text.trim());
    int numQ = int.parse(numQuestionsController.text.trim());
    double pay = double.parse(payoutController.text.trim());
    final deadlineString = deadlineController.text.trim();

    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final surveyData = {
      'title': titleController.text.trim(),
      'url': urlController.text.trim(),
      'maxRespondents': maxResp,
      'deadline': deadlineString,
      'numQuestions': numQ,
      'payout': pay,
      'resp': 0,
      'status': status,
      'userId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      CollectionReference surveys = FirebaseFirestore.instance.collection('surveys');
      await surveys.add(surveyData);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Survey Submitted'),
            content: const Text('Your survey has been submitted successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              )
            ],
          );
        },
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to create survey: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              )
            ],
          );
        },
      );
    }
  }

  void handleSubmit() {
    if (_formKey.currentState!.validate()) {
      saveSurveyToFirestore();
    }
  }

  Widget buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        style: GoogleFonts.poppins(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.black87),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
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
          'Create Survey',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Text(
                    'Survey Details',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                buildTextField(
                  label: 'Title',
                  hint: 'Enter Title Here...',
                  controller: titleController,
                  validator: validateTitle,
                ),
                buildTextField(
                  label: 'URL',
                  hint: 'Enter Google Forms URL',
                  controller: urlController,
                  keyboardType: TextInputType.url,
                  validator: validateUrl,
                ),
                buildTextField(
                  label: 'Max Respondents',
                  hint: 'Enter Value (Max 1000)...',
                  controller: maxRespondentsController,
                  keyboardType: TextInputType.number,
                  validator: validateMaxRespondents,
                ),
                buildTextField(
                  label: 'Deadline',
                  hint: 'Tap to pick a date',
                  controller: deadlineController,
                  readOnly: true,
                  onTap: pickDeadlineDate,
                  validator: validateDeadline,
                ),
                buildTextField(
                  label: 'No. of Questions',
                  hint: 'Enter Value (Max 100)...',
                  controller: numQuestionsController,
                  keyboardType: TextInputType.number,
                  validator: validateNumQuestions,
                ),
                buildTextField(
                  label: 'Per Person Payout',
                  hint: 'Enter Value...',
                  controller: payoutController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: validatePayout,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ElevatedButton(
                    onPressed: handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Submit Survey',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
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
          selectedIndex: 3,
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
}