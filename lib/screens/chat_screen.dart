import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _fireStore = FirebaseFirestore.instance;
User loginUser;
String openEmail;
String opening;

class ChatScreen extends StatefulWidget {
  static const id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messagetextController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  String message;
  @override
  void initState() {
    super.initState();

    //getCurrentUser();
  }

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;

      if (user != null) {
        loginUser = user;
        print('OpenedEmail = ' + openEmail);
        print('LoginEmail = ' + loginUser.email);
        openEmail.compareTo(loginUser.email) > 0
            ? opening = openEmail + loginUser.email
            : opening = loginUser.email + openEmail;
        print('opening = ' + opening);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context).settings.arguments as Map;
    if (arguments != null) openEmail = arguments['email'];
    print('&&&&&&&' + openEmail);
    getCurrentUser();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: null,
        actions: <Widget>[],
        elevation: 30,
        title: Center(
          child: Text(
            '⚡️$openEmail',
          ),
        ),
        backgroundColor: Colors.blueGrey,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: Colors.blueGrey[600]),
                      controller: messagetextController,
                      onChanged: (value) {
                        message = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      if (message != null) {
                        print('######' + opening);
                        messagetextController.clear();
                        _fireStore.collection(opening).add({
                          'data': message,
                          'sender': loginUser.email,
                          'time': Timestamp.now()
                        });
                      }
                      message = null;
                    },
                    child: Text(
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

class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _fireStore
            .collection(opening)
            .orderBy('time', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.brown[600],
              ),
            );
          }
          {
            final messages = snapshot.data.docs;
            List<MessageBox> messageWidget = [];
            for (var message in messages) {
              print('Messages Opened = ' + opening);
              final text = message['data'];
              final time = message['time'];
              final sender = message['sender'];
              final box = MessageBox(
                text: text,
                time: time,
                own: sender == loginUser.email ? true : false,
              );
              messageWidget.add(box);
            }
            return Expanded(
              child: ListView(
                reverse: true,
                children: messageWidget,
              ),
            );
          }
        });
  }
}

class MessageBox extends StatelessWidget {
  MessageBox({
    @required this.text,
    @required this.time,
    this.own,
  });
  final text;
  final Timestamp time;
  final bool own;
  double radius = 40;
  double sides = 130;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 15),
      child: Column(
        crossAxisAlignment:
            own ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                own ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Material(
                elevation: 10,
                borderRadius: own
                    ? BorderRadius.only(
                        topLeft: Radius.elliptical(sides, sides),
                        bottomLeft: Radius.circular(radius),
                        bottomRight: Radius.circular(radius),
                      )
                    : BorderRadius.only(
                        topRight: Radius.elliptical(sides, sides),
                        bottomLeft: Radius.circular(radius),
                        bottomRight: Radius.circular(radius),
                      ),
                color: own ? Colors.blueAccent : Colors.lightBlueAccent,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      child: Text(
                        '$text',
                        style: TextStyle(
                          fontSize: 20,
                          color: !own ? Colors.white : Colors.white,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          top: 20.0, right: 8, left: 8, bottom: 8),
                      child: Text(
                        time.toDate().hour.toString() +
                            ':' +
                            time.toDate().minute.toString(),
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
