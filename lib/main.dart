import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MentaRayMessagingApp());
}

class MentaRayMessagingApp extends StatelessWidget {
  const MentaRayMessagingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Menta-Ray Messaging',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MessagingScreen(),
    );
  }
}

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  // The Data Highway connects to the 'shared_note' key in your cloud database
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('shared_note');
  final TextEditingController _controller = TextEditingController();
  
  String _currentMessage = "Waiting for messages...";
  bool _isCardOpen = false;

  @override
  void initState() {
    super.initState();
    // Listen for live updates
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          _currentMessage = data['text'] ?? "No message yet!";
        });
      }
    });
  }

  // The Trigger to send data
  void _sendNote() {
    if (_controller.text.isNotEmpty) {
      _dbRef.set({
        'text': _controller.text,
        'timestamp': ServerValue.timestamp,
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], 
      body: Stack(
        children: [
          // The Messaging Card
          if (_isCardOpen)
            Positioned(
              bottom: 90,
              right: 20,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Live Message:",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 8),
                      Text(_currentMessage),
                      const Divider(),
                      TextField(
                        controller: _controller,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _sendNote,
                          child: const Text("Send"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // The Mascot UI Button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isCardOpen = !_isCardOpen;
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0, 
              child: Image.asset(
                'assets/penguin.png',
                width: 50,  
                height: 50,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}