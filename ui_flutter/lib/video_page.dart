
import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui_flutter/main.dart';
import 'src/authentication.dart';
import 'src/widgets.dart';

class VideoPage extends StatefulWidget {

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  
  // String _selectedOption = 'Good';
  String? _selectedOption;
  bool _isWatching = false;
  bool _isConfirmed = false;
  bool _addNewDoc = false;
  String fileName = 'null';

  void saveWatchRecord(String value, DateTime time) {

    final userDocRef = FirebaseFirestore.instance.collection('Users').doc(FirebaseAuth.instance.currentUser!.uid).collection('Mood Records');

    if (_addNewDoc) {
      fileName = DateFormat('yyyy-MM-dd HH:mm:ss').format(time);
      userDocRef.doc(fileName).set({
        'Before Watch Mood': value,
        'Start Watch Time': DateFormat('yyyy-MM-dd HH:mm:ss').format(time),
      });
    } else {
      userDocRef.doc(fileName).update({
        'After Watch Mood': value,
        'Stop Watch Time': DateFormat('yyyy-MM-dd HH:mm:ss').format(time),
      });
    }
  }

  Future<bool> _showDialog() async {
    _selectedOption = null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('How do you feel now?'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  RadioListTile<String>(
                    title: Text('Good'),
                    value: 'Good',
                    hoverColor: Colors.pink[100],
                    activeColor: Colors.pink[400],
                    onChanged: (value) {
                      setState(() {
                        _selectedOption = value!;
                        // Navigator.of(context).pop();
                      });
                    },
                    groupValue: _selectedOption,
                  ),
                  RadioListTile<String>(
                    title: Text('Okay'),
                    value: 'Okay',
                    hoverColor: Colors.pink[100],
                    activeColor: Colors.pink[400],
                    onChanged: (value) {
                      setState(() {
                        _selectedOption = value!;
                        // Navigator.of(context).pop();
                      });
                    },
                    groupValue: _selectedOption,
                  ),
                  RadioListTile<String>(
                    title: Text('Not good'),
                    value: 'Not good',
                    hoverColor: Colors.pink[100],
                    activeColor: Colors.pink[400],
                    onChanged: (value) {
                      setState(() {
                        _selectedOption = value!;
                        // Navigator.of(context).pop();
                      });
                    },
                    groupValue: _selectedOption,
                  ),
                ],
                
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isConfirmed = false;
                });
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (_selectedOption != null) {
                  saveWatchRecord(_selectedOption!, DateTime.now());
                }
                setState(() {
                  _isConfirmed = true;
                });
              },
              child: Text('Confirm'),
            )
          ],
        );
      },
    );

    return _isConfirmed;
  }

  void _startWatching() async {
    if (!_isWatching) {
      setState(() {
        _addNewDoc = true;
      });
      _isConfirmed = await _showDialog();
      if (_isConfirmed) {
        setState(() {
          _isWatching = true;
          _isConfirmed = false;
        });
      } else {
        setState(() {
          _isWatching = false;
        });
      }
    } else {
      _showAlert('You are already watching.');
    }
  }

  void _stopWatching() async {
    if (_isWatching) {
      setState(() {
        _addNewDoc = false;
      });
      _isConfirmed = await _showDialog();
      if (_isConfirmed) {
        setState(() {
          _isWatching = false;
          _isConfirmed = false;
        });
      } else {
        setState(() {
          _isWatching = true;
        });
      }
    } else {
      _showAlert('You are not watching anything.');
    }
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watching Videos'),
      ),
      body: Column(
        // mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Spacer(flex: 1),
          Center(
            child: FractionallySizedBox(
              widthFactor: 2/3,
              child: ElevatedButton(
                onPressed:  _startWatching, 
                child: Text('Start Watching'),
              ),
            ),
          ),
          
          // SizedBox(height: 50),
          Spacer(flex: 1),
          Center(
            child: FractionallySizedBox(
              widthFactor: 2/3,
              child: ElevatedButton(
                onPressed: _stopWatching, 
                child: Text('Stop Watching'),
              ),
            ),
          ),
          
          Spacer(flex: 2),
        ],
      ),
    );
  }
}