
import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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

  Future<void> _showDialog() async {
    _selectedOption = null;
    setState(() {
      _isConfirmed = false;
    });
    

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
                setState(() {
                  _isConfirmed = false;
                });
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isConfirmed = true;
                });
                if (_selectedOption != null) {
                  saveWatchRecord(_selectedOption!, DateTime.now());
                }
                Navigator.of(context).pop();
              },
              child: Text('Confirm'),
            )
          ],
        );
      },
    );
  }

  void _startWatching() async {
    if (_isConfirmed && _addNewDoc) {
      setState(() {
        _isWatching = true;
      });
    } else if (!_isConfirmed && _addNewDoc) {
      setState(() {
        _isWatching = false;
      });
    } else if (_isConfirmed && !_addNewDoc) {
      setState(() {
        _isWatching = false;
      });
    } else {
      
    }

    if (!_isWatching) {
      setState(() {
        _addNewDoc = true;
      });
      
      await _showDialog();
       
    } else {
      _showAlert('You are already watching.');
    }
  }

  void _stopWatching() async {
    if (!_isConfirmed && _addNewDoc) {
      setState(() {
        _isWatching = false;
      });
    } else if (_isConfirmed && _addNewDoc) {
      setState(() {
        _isWatching = true;
      });
    } else if (_isConfirmed && !_addNewDoc) {
      setState(() {
        _isWatching = false;
      });
    } else {

    }

    if (_isWatching) {
      setState(() {
        _addNewDoc = false;
      });
      await _showDialog();
      
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
        title: const Text(
          'Watching Videos',
          style: TextStyle(
            color: Color.fromRGBO(72, 61, 139, 1),
          ),
          ),
      ),
      body: Column(
        // mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Spacer(flex: 1),
          Center(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 80, right: 60),
                  child: Text(
                    'Everytime you want to use YouTube, press the "START" button first!',
                    style: TextStyle(
                        color: Color.fromRGBO(72, 61, 139, 0.5),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      // background: Paint()..color = Colors.pink[400]!,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.purple[200],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed:  _startWatching, 
                  child: Icon(Icons.play_circle_sharp, size: 50),
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(150, 120),
                    side: BorderSide(
                      width: 2,
                      color: Color.fromRGBO(72, 61, 139, 0.5),
                      style: BorderStyle.solid,
                      strokeAlign:  BorderSide.strokeAlignOutside,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  )
                ),
              ],
            ),
          ),
          
          // SizedBox(height: 50),
          Spacer(flex: 1),
          Center(
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _stopWatching, 
                  child: Icon(Icons.stop_circle_sharp, size: 50),
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(150, 120),
                    side: BorderSide(
                      width: 2,
                      color: Color.fromRGBO(72, 61, 139, 0.5),
                      style: BorderStyle.solid,
                      strokeAlign:  BorderSide.strokeAlignOutside,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  )
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 80, right: 60),
                  child: Text(
                    'Remember to press "Stop" button after you finish watching!',
                    style: TextStyle(
                        color: Color.fromRGBO(72, 61, 139, 0.5),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      // background: Paint()..color = Colors.pink[400]!,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.purple[200],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Spacer(flex: 1),
        ],
      ),
    );
  }
}