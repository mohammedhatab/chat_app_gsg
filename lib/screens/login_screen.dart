import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/main_btn.dart';
import '../constants.dart';
import 'chat_screen.dart';

class LoginScreen extends StatefulWidget {
  static const id = 'LoginScreen';
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoggedIn
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Hero(
                    tag: 'logo',
                    child: SizedBox(
                      height: 200.0,
                      child: Image.asset('images/logo.png'),
                    ),
                  ),
                  const SizedBox(
                    height: 48.0,
                  ),
                  TextField(
                    controller: email,
                    decoration: kTextFieldDecoration.copyWith(
                        hintText: 'Enter your Email'),
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: kTextFieldDecoration.copyWith(
                        hintText: 'Enter your Password'),
                  ),
                  const SizedBox(
                    height: 24.0,
                  ),
                  MainBtn(
                    color: Colors.lightBlueAccent,
                    text: 'Log In',
                    onPressed: () async {
                      try {
                        setState(() {
                          isLoggedIn = true;
                        });
                        // if (email.text != null && password.text != null) {
                        final newUser = await _auth.signInWithEmailAndPassword(
                            email: email.text, password: password.text);
                        if (newUser.user != null && mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            ChatScreen.id,
                            (_) => false,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('welcome ${newUser.user!.email}')));
                        }
                        // }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                                Text('${e.toString().split(']')[1].trim()}')));
                      }
                      setState(() {
                        isLoggedIn = false;
                      });
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
