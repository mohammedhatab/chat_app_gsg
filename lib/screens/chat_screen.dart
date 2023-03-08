import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chat_app_class/screens/welcome_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' as INTL;

import '../constants.dart';
import 'notifications_screen.dart';

class ChatScreen extends StatefulWidget {
  static const id = 'ChatScreen';

  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? currentBackPressTime;
  TextEditingController controller = TextEditingController();
  dynamic messages;
  String? currentUserEmail;
  Timer? _timer;
  String? typingId;

  List<RemoteNotification?> notifications = [];
  String token = '';

  void getCurrentUser() {
    final currentUser = _auth.currentUser!;
    currentUserEmail = currentUser.email;
  }

  void getMessages() async {
    messages = await _firestore
        .collection('messages')
        .orderBy(
          'dateTime',
          descending: true,
        )
        .get();
    setState(() {});
  }

  void getNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        setState(() {
          notifications.add(notification);
        });
      }
    });
  }

  Future<void> sendNotification(String title, String body) async {
    http.Response response = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/my-chat-app-gsg/messages:send'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $token'
        },
        body: jsonEncode({
          "message": {
            "topic": "chat",
            "notification": {"title": title, "body": body},
          }
        }));
  }

  Future<AccessToken> getAccessToken() async {
    final serviceAccount = await rootBundle.loadString(
        'assets/my-chat-app-gsg-firebase-adminsdk-qwav3-50e5e5285d.json');
    final data = await jsonDecode(serviceAccount);
    final accountCredentials = ServiceAccountCredentials.fromJson({
      "private_key_id": data['private_key_id'],
      "private_key": data['private_key'],
      "client_email": data['client_email'],
      "client_id": data['client_id'],
      "type": data['type']
    });
    final scopes = ["https://www.googleapis.com/auth/firebase.messaging"];
    final AuthClient authClient =
        await clientViaServiceAccount(accountCredentials, scopes)
          ..close();

    return authClient.credentials.accessToken;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    getCurrentUser();
    getAccessToken().then((value) => token = value.data);

    getNotifications();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      getMessages();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: null,
          actions: <Widget>[
            notifications.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, NotificationsScreen.id,
                              arguments: notifications)
                          .then((value) => setState(() {
                                notifications.clear();
                              }));
                    },
                    child: Stack(
                      children: [
                        const Center(child: Icon(Icons.notifications)),
                        Container(
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                          child: Text(notifications.length.toString()),
                        )
                      ],
                    ),
                  )
                : const SizedBox(),
            IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  _auth.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, WelcomeScreen.id, (_) => false);
                }),
          ],
          title: const Text('⚡️Chat'),
          backgroundColor: Colors.lightBlueAccent,
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              messages == null
                  ? const Text('')
                  : Expanded(
                      child: StreamBuilder(
                          stream: _firestore
                              .collection('messages')
                              .orderBy('dateTime', descending: true)
                              .snapshots(),
                          builder: (context, snapshot2) {
                            if (snapshot2.hasData) {
                              dynamic messages = snapshot2.data!.docs;
                              return ListView.builder(
                                reverse: true,
                                itemCount: messages.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 12),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Directionality(
                                            textDirection: messages[index]
                                                        ['sender'] ==
                                                    currentUserEmail
                                                ? TextDirection.ltr
                                                : TextDirection.rtl,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  messages[index]['sender']
                                                      .toString()
                                                      .split('@')
                                                      .first,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.blue),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: messages[index]
                                                      ['sender'] ==
                                                  currentUserEmail
                                              ? Alignment.topRight
                                              : Alignment.topLeft,
                                          child: Container(
                                            constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.4),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.only(
                                                  topLeft:
                                                      const Radius.circular(20),
                                                  topRight:
                                                      const Radius.circular(20),
                                                  bottomLeft: messages[index]
                                                              ['sender'] ==
                                                          currentUserEmail
                                                      ? const Radius.circular(
                                                          20)
                                                      : const Radius.circular(
                                                          0),
                                                  bottomRight: messages[index]
                                                              ['sender'] ==
                                                          currentUserEmail
                                                      ? const Radius.circular(0)
                                                      : const Radius.circular(
                                                          20)),
                                              color: messages[index]
                                                          ['sender'] ==
                                                      currentUserEmail
                                                  ? const Color(0xFF1B97F3)
                                                  : const Color(0xFF9CA1A2),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    messages[index]['sender'] ==
                                                            currentUserEmail
                                                        ? CrossAxisAlignment.end
                                                        : CrossAxisAlignment
                                                            .start,
                                                children: [
                                                  const SizedBox(
                                                    height: 5,
                                                  ),
                                                  Text(
                                                    messages[index]['text'],
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16),
                                                  ),
                                                  const SizedBox(
                                                    height: 5,
                                                  ),
                                                  Align(
                                                    alignment:
                                                        Alignment.bottomRight,
                                                    child: Text(
                                                      INTL.DateFormat('h:mm a')
                                                          .format(DateTime
                                                              .fromMicrosecondsSinceEpoch(
                                                                  messages[index]
                                                                          [
                                                                          'dateTime']
                                                                      .microsecondsSinceEpoch))
                                                          .toString(),
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.white
                                                              .withAlpha(120)),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            } else {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                          })),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StreamBuilder(
                      stream: _firestore.collection('typing_users').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          List<dynamic> users = snapshot.data!.docs;

                          if (users.length == 1) {
                            if (users[0]['user'] == currentUserEmail) {
                              users.clear();
                            }
                          }
                          if (users.length != 0) {
                            String listOfEmails = '';
                            for (var user in users) {
                              if (user['user'] != currentUserEmail) {
                                listOfEmails +=
                                    '${user['user'].split('@').first} ,';
                              }
                            }

                            if (users.length > 3) {
                              listOfEmails = 'multiple users are typing';
                            }

                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '$listOfEmails is typing ...',
                              ),
                            );
                          } else {
                            return const SizedBox();
                          }
                        }
                        return const SizedBox();
                      }),
                  Container(
                    decoration: kMessageContainerDecoration,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: kMessageTextFieldDecoration,
                            onChanged: (text) {
                              if (_timer?.isActive ?? false) _timer?.cancel();
                              _timer = Timer(const Duration(milliseconds: 500),
                                  () async {
                                if (text.isNotEmpty) {
                                  if (typingId == null) {
                                    final reference = await _firestore
                                        .collection('typing_users')
                                        .add({'user': currentUserEmail});
                                    typingId = reference.id;
                                  }
                                } else if (controller.text.isEmpty) {
                                  _firestore
                                      .collection('typing_users')
                                      .doc(typingId)
                                      .delete();
                                  typingId = null;
                                }
                              });
                            },
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (controller.text.isNotEmpty) {
                              _firestore.collection('messages').add({
                                'text': controller.text,
                                'sender': currentUserEmail,
                                'dateTime': DateTime.now()
                              });
                            }
                            sendNotification('Message from $currentUserEmail',
                                controller.text);
                            controller.clear();

                            Future.delayed(const Duration(seconds: 1), () {
                              if (typingId != null) {
                                _firestore
                                    .collection('typing_users')
                                    .doc(typingId)
                                    .delete();
                                typingId = null;
                              }
                            });
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
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.showToast(msg: 'Hit back again to exit');
      return Future.value(false);
    }
    return Future.value(true);
  }
}
