import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  var _isLogin = true;
  var _userEmail = '';
  var _userName = '';
  var _userPassword = '';
  File? _selectedImage;
  var _isAuthenticating = false;

  void _trySubmit() async {
    final _isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();
    if (!_isValid || !_isLogin && _selectedImage == null) {
      return;
    }
    if (_isValid) {
      _formKey.currentState!.save();
      try {
        setState(() {
          _isAuthenticating = true;
        });
        if (_isLogin) {
          final userCredential = await _firebase.signInWithEmailAndPassword(
              email: _userEmail, password: _userPassword);
        } else {
          final userCredential = await _firebase.createUserWithEmailAndPassword(
              email: _userEmail, password: _userPassword);
          final storageRef = await FirebaseStorage.instance
              .ref()
              .child('user_images')
              .child('${userCredential.user!.uid}.jpg');
          await storageRef.putFile(_selectedImage!);
          final imageUrl = await storageRef.getDownloadURL();
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'username': _userName,
            'email': _userEmail,
            'image_url': imageUrl,
          });
          print(imageUrl);
        }
      } on FirebaseAuthException catch (error) {
        if (error.code == 'invalid-email') {
          //...
        }
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Authentication Failed.'),
          ),
        );
      }
      setState(() {
        _isAuthenticating = false;
      });
    }
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
                    top: 30, bottom: 20, left: 20, right: 20),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_isLogin)
                              UserImagePicker(
                                onPickImage: (pickedImage) {
                                  _selectedImage = pickedImage;
                                },
                              ),
                            TextFormField(
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    !value.contains('@')) {
                                  return 'Insert a valid email address!';
                                }
                                return null;
                              },
                              key: ValueKey('userEmail'),
                              decoration: const InputDecoration(
                                labelText: 'E-mail address.',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              onSaved: (value) {
                                _userEmail = value!;
                              },
                            ),
                            if (!_isLogin)
                              TextFormField(
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty ||
                                      value.length < 4) {
                                    return 'Username must be 4 characters';
                                  }
                                  return null;
                                },
                                key: ValueKey('userName'),
                                decoration: const InputDecoration(
                                  labelText: 'User name.',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                onSaved: (value) {
                                  _userName = value!;
                                },
                              ),
                            TextFormField(
                              textInputAction: TextInputAction.done,
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    value.length < 6) {
                                  return 'Password must be more than 6 characters';
                                }
                                return null;
                              },
                              key: const ValueKey('userPassword'),
                              decoration: const InputDecoration(
                                labelText: 'Password.',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              obscureText: true,
                              onSaved: (value) {
                                _userPassword = value!;
                              },
                            ),
                            const SizedBox(height: 12),
                            if (_isAuthenticating)
                              Center(
                                child: const CircularProgressIndicator(),
                              ),
                            if (!_isAuthenticating)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer),
                                child: Text(_isLogin ? 'Login' : 'Signup'),
                                onPressed: _trySubmit,
                              ),
                            if (!_isAuthenticating)
                              TextButton(
                                child: Text(_isLogin
                                    ? 'Create an account'
                                    : 'I already have an account'),
                                onPressed: () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                  });
                                },
                              )
                          ],
                        )),
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
