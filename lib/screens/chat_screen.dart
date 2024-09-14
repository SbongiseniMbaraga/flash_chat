import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
User? loggedInUser;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  static const String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  late String messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        if (kDebugMode) {
          print(loggedInUser?.email);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _handleSignOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.signOut();
      Navigator.pop(context);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          Stack(
            children: [
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    //_handleSignOut;
                    _handleSignOut();
                  }),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        ],
        title: const Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      messageTextController.clear();
                      _firestore.collection('messages').add(
                        {
                          'text': messageText,
                          'sender': loggedInUser?.email,
                          'timestamp': FieldValue.serverTimestamp(),
                        },
                      );
                    },
                    child: const Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  const MessagesStream({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _firestore
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final messages = snapshot.data?.docs;
          List<MessageBubble> messageBubbles = [];
          for (var message in messages!) {
            final messageText = message.data()['text'];
            final messageSender = message.data()['sender'];
            final currentUser = loggedInUser?.email;

            final messageBubble = MessageBubble(
              sender: messageSender,
              text: messageText,
              isMe: currentUser == messageSender,
            );
            messageBubbles.add(messageBubble);
          }
          return Expanded(
            child: ListView(
              reverse: true,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              children: messageBubbles,
            ),
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble(
      {super.key,
      required this.sender,
      required this.text,
      required this.isMe});
  final String text;
  final String sender;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: const TextStyle(
              fontSize: 12.0,
              color: Colors.black54,
            ),
          ),
          Material(
            elevation: 5.0,
            borderRadius: BorderRadius.only(
              topLeft: isMe
                  ? const Radius.circular(30.0)
                  : const Radius.circular(0.0),
              topRight: isMe
                  ? const Radius.circular(0.0)
                  : const Radius.circular(30.0),
              bottomLeft: const Radius.circular(30.0),
              bottomRight: const Radius.circular(30.0),
            ),
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black54,
                  fontSize: 15.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
