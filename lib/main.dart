import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Failed to start: $e')))));
    return;
  }
  runApp(const MentaRayMessagingApp());
}

class MentaRayMessagingApp extends StatelessWidget {
  const MentaRayMessagingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Menta-Ray Messaging',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 1, 21, 49)),
      ),
      home: const MessagingScreen(userId: 'sherlyn'),
    );
  }
}

class MessagingScreen extends StatefulWidget {
  final String userId;
  const MessagingScreen({super.key, required this.userId});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('messages');
  final TextEditingController _controller = TextEditingController();
  late final StreamSubscription<DatabaseEvent> _subscription;

  String _currentMessage = "Waiting for messages...";
  String? _lastSenderId;
  bool _isCardOpen = false;
  bool _isSending = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final lastMessageQuery = _dbRef.orderByChild('timestamp').limitToLast(1);
    _subscription = lastMessageQuery.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return;

      final entry = data.entries.first.value;
      if (entry is! Map) return;

      final text = entry['text'] as String?;
      final senderId = entry['senderId'] as String?;
      if (text == null) return;

      setState(() {
        _currentMessage = text;
        _lastSenderId = senderId;
        if (senderId != widget.userId) {
          _isCardOpen = true;
        }
      });
    }, onError: (error) {
      setState(() {
        _errorText = 'Connection error: $error';
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendNote() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _errorText = null;
    });

    try {
      await _dbRef.push().set({
        'text': text,
        'senderId': widget.userId,
        'timestamp': ServerValue.timestamp,
      });
      _controller.clear();
    } catch (e) {
      setState(() {
        _errorText = 'Failed to send: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          if (_isCardOpen)
            Positioned(
              bottom: 90 + viewInsets,
              right: 20,
              left: 20,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _lastSenderId != null && _lastSenderId != widget.userId
                                ? "$_lastSenderId says:"
                                : "New message!",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 1, 21, 49),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _isCardOpen = false),
                            child: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_currentMessage),
                      const Divider(),
                      if (_errorText != null) ...[
                        Text(_errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        const SizedBox(height: 4),
                      ],
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
                          onPressed: _isSending ? null : _sendNote,
                          child: _isSending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text("Send"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isCardOpen = !_isCardOpen;
                });
              },
              child: Image.asset(
                'assets/penguin.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.emoji_emotions, size: 100);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}