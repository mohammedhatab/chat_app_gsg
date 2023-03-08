import 'package:chat_app_class/constants.dart';
import 'package:chat_app_class/screens/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/main_btn.dart';

class RegistrationScreen extends StatefulWidget {
  static const id = 'RegistrationScreen';
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  String? email;
  String? password;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void getLoginState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {});
  }

  @override
  void initState() {
    super.initState();
    getLoginState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 200.0,
              child: Image.asset('images/logo.png'),
            ),
            const SizedBox(
              height: 48.0,
            ),
            TextField(
              onChanged: (value) {
                setState(() {
                  email = value;
                });
              },
              decoration:
                  kTextFieldDecoration.copyWith(hintText: 'Enter your Email'),
            ),
            const SizedBox(
              height: 8.0,
            ),
            TextField(
              onChanged: (value) {
                setState(() {
                  password = value;
                });
              },
              obscureText: true,
              decoration: kTextFieldDecoration.copyWith(
                  hintText: 'Enter your password'),
            ),
            const SizedBox(
              height: 24.0,
            ),
            MainBtn(
              color: Colors.blueAccent,
              text: 'Register',
              onPressed: () async {
                try {
                  if (email != null && password != null) {
                    final newUser = await _auth.createUserWithEmailAndPassword(
                        email: email!, password: password!);
                    if (newUser.user != null && mounted) {
                      Navigator.pushNamed(context, ChatScreen.id);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('welcome ${newUser.user!.email}')));
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${e.toString().split(']')[1].trim()}')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
