import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:maximilian_chat_app/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maximilian_chat_app/widgets/user_image_picker_widget.dart';

class AuthenticaitonScreen extends StatefulWidget {
  const AuthenticaitonScreen({super.key});

  @override
  State<AuthenticaitonScreen> createState() => _AuthenticaitonScreenState();
}

final auth = FirebaseAuth.instance;

class _AuthenticaitonScreenState extends State<AuthenticaitonScreen> {
  final _form = GlobalKey<FormState>();
  var _isLogin = true;
  var enteredEmail = '';
  var enteredPassword = '';
  var enteredUsername = '';
  File? _selectedImage;
  var _isAuthenticating = false;

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid || (!_isLogin && _selectedImage == null)) {
      return;
    }

    _form.currentState!.save();
    try {
      if (_isLogin) {
        final userCredential = await auth.signInWithEmailAndPassword(
          email: enteredEmail,
          password: enteredPassword,
        );
        print(userCredential);
      } else {
        setState(() {
          _isAuthenticating = true;
        });
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: enteredEmail,
          password: enteredPassword,
        );

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredential.user!.uid}.jpg');

        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'user name': enteredUsername,
          'email': enteredEmail,
          'image url': imageUrl,
        });
      }
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message!,
          ),
        ),
      );
    }
    setState(() {
      _isAuthenticating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                width: 200,
                child: Image.asset(chatImagePath),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _form,
                      child: Column(
                        children: [
                          if (!_isLogin)
                            UserImagePicker(
                              onPickedImage: (pickedImage) {
                                _selectedImage = pickedImage;
                              },
                            ),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              enteredEmail = value!;
                            },
                          ),
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Username'),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value.trim().length < 4) {
                                return 'please enter at least 4 characters';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              enteredUsername = value!;
                            },
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return 'Please enter a valid password';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              enteredPassword = value!;
                            },
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          if (_isAuthenticating)
                            const CircularProgressIndicator(),
                          if (!_isAuthenticating)
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                              ),
                              child: Text(_isLogin ? 'Login' : 'Sign up'),
                            ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                            child: Text(_isLogin
                                ? 'Create an account'
                                : 'Already have an account?'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
