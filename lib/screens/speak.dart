import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';

class SpeakScreen extends StatefulWidget {
  @override
  _SpeakScreenState createState() => _SpeakScreenState();
}

class _SpeakScreenState extends State<SpeakScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  double _confidence = 1.0;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// Initialize speech recognition
  void _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('onStatus: $status'),
      onError: (errorNotification) => print('onError: $errorNotification'),
    );
    if (!available) {
      setState(() {
        _text = 'Speech recognition not available on this device';
      });
    }
  }

  /// Start or stop listening to speech
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('onStatus: $status');
          if (status == 'done') {
            setState(() {
              _isListening = false;
            });
          }
        },
        onError: (errorNotification) {
          print('onError: $errorNotification');
          setState(() {
            _isListening = false;
          });
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
              if (result.hasConfidenceRating && result.confidence > 0) {
                _confidence = result.confidence;
              }
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  /// Copy text to clipboard
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Text copied to clipboard')),
    );
  }

  /// Clear the recognized text
  void _clearText() {
    setState(() {
      _text = 'Press the button and start speaking';
      _confidence = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speech to Text'),
        actions: [
          IconButton(
            icon: Icon(Icons.content_copy),
            onPressed: _text != 'Press the button and start speaking' ? _copyToClipboard : null,
            tooltip: 'Copy to clipboard',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: _text != 'Press the button and start speaking' ? _clearText : null,
            tooltip: 'Clear text',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(16),
            child: Text(
              'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Container(
                  width: double.infinity,
                  child: Text(
                    _text,
                    style: TextStyle(
                      fontSize: 18,
                    ),
                    softWrap: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        tooltip: 'Listen',
        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }
}