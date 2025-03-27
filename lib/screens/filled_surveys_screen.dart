import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class FilledSurveysScreen extends StatelessWidget {
  const FilledSurveysScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget buildInfoRow(String deadline, int numQuestions, int resp, int maxRespondents) {
    return Row(
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(deadline.isNotEmpty ? deadline : 'No Deadline', style: const TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            const Icon(Icons.help_outline, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('$numQuestions', style: const TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            const Icon(Icons.person, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('$resp/$maxRespondents', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget buildStatusOrPayout(String status, double payout) {
    if (status.toUpperCase() == "OPEN" || status.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Rs. ${payout.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.white),
        ),
      );
    } else {
      return Container();
    }
  }

  Future<void> _removeFromFilled(String filledDocId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('filled').doc(filledDocId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Survey removed from filled list')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing survey: $e')),
      );
    }
  }

  // Different name to avoid conflict with home_screen.dart
  Widget buildFilledSurveyItem(DocumentSnapshot surveyDoc, String filledDocId, BuildContext context) {
    final data = surveyDoc.data() as Map<String, dynamic>;
    final String title = data['title'] ?? 'No Title';
    final String deadline = data['deadline'] ?? '';
    final int numQuestions = data['numQuestions'] ?? 0;
    final int maxRespondents = data['maxRespondents'] ?? 0;
    final double payout = (data['payout'] ?? 0).toDouble();
    final String status = data['status'] ?? 'OPEN';
    final int resp = data['resp'] ?? 0;
    final String url = data['url'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              if (url.isNotEmpty) {
                _launchUrl(url);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No URL available for this survey')),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  buildInfoRow(deadline, numQuestions, resp, maxRespondents),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      buildStatusOrPayout(status, payout),
                      Row(
                        children: [
                          const Icon(Icons.archive, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          const Text('Filled', style: TextStyle(color: Colors.blue, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Remove button
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: () => _removeFromFilled(filledDocId, context),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('You need to be logged in to view filled surveys')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filled Surveys'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('filled')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, filledSnapshot) {
          if (filledSnapshot.hasError) {
            return const Center(child: Text('Error loading filled surveys.'));
          }
          if (filledSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final filledDocs = filledSnapshot.data?.docs ?? [];
          if (filledDocs.isEmpty) {
            return const Center(child: Text('No filled surveys found.'));
          }

          return ListView.builder(
            itemCount: filledDocs.length,
            itemBuilder: (context, index) {
              final filledDoc = filledDocs[index];
              final String surveyId = filledDoc['surveyId'] as String;
              final String filledDocId = filledDoc.id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('surveys').doc(surveyId).get(),
                builder: (context, surveySnapshot) {
                  if (surveySnapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  if (surveySnapshot.hasError || !surveySnapshot.hasData || !surveySnapshot.data!.exists) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Survey no longer available',
                                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeFromFilled(filledDocId, context),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return buildFilledSurveyItem(surveySnapshot.data!, filledDocId, context);
                },
              );
            },
          );
        },
      ),
    );
  }
}