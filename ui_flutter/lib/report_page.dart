import 'dart:ffi';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import 'src/authentication.dart';
import 'src/widgets.dart';

import 'chart_page.dart';

final db = FirebaseFirestore.instance;






class ReportPage extends StatelessWidget {
  // const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    // final appState = Provider.of<ApplicationState>(context);
    // final uid = appState.userUid;
    // final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Page'),
      ),
      body: ListView(
        children: <Widget>[
          const Header('Upload Your YouTube Watching History Here'),
          ElevatedButton(
            onPressed: () async {
              await uploadFile(FirebaseAuth.instance.currentUser!.uid);
              print('File uploaded');
              sendCommand(true, FirebaseAuth.instance.currentUser!.uid);
              print('working');
            }, 
            child: Text('Upload File'),
          ),
          ElevatedButton(
            onPressed: () {
              DateTime now = DateTime.now();
              DateTime startLastWeek = DateTime(now.year, now.month, now.day - 6, 0, 0, 0);
              DateTime endToday = DateTime(now.year, now.month, now.day + 1,0, 0, 0);

              String lastWeekStartDay = startLastWeek.toString().substring(0, 19);
              String endTodayDay = endToday.toString().substring(0, 19);
              print(lastWeekStartDay);
              print(endTodayDay);
              handleData(true, FirebaseAuth.instance.currentUser!.uid, lastWeekStartDay, endTodayDay);
              
            },
            child: Text('Report Generation'),
          ),
          ElevatedButton(
            onPressed: () {
              DateTime now = DateTime.now();
              DateTime startLastWeek = DateTime(now.year, now.month, now.day - 6, 0, 0, 0);
              DateTime endToday = DateTime(now.year, now.month, now.day + 1,0, 0, 0);

              String lastWeekStartDay = startLastWeek.toString().substring(0, 19);
              String endTodayDay = endToday.toString().substring(0, 19);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChartPage(
                  startDate: startLastWeek,
                  endDate: endToday,
                ))
              );
            },
            child: Text('Generate Your Viewing Behaviours Report'),
          ),
          ElevatedButton(
            onPressed: () {
              List<DateTime> dates = [
                DateTime(2024, 4, 1),
                DateTime(2024, 4, 2),
                DateTime(2024, 4, 3),
                DateTime(2024, 4, 4),
                DateTime(2024, 4, 5),
                DateTime(2024, 4, 6),
              ];
              
              for (int i = 0; i < dates.length; i++){
                String date = dates[i].toIso8601String().substring(0, 10);
                db.collection('Users').doc(FirebaseAuth.instance.currentUser!.uid).collection('Report').doc(date).collection('Summary').doc(date).get().then(
                  (DocumentSnapshot doc) {
                    if (doc.exists) {
                      final data = doc.data() as Map<String, dynamic>;
                      int num = data['Today_watched_video_number'];
                      print(num);
                    } else {
                      print('No such document');
                    }
                    
                  },
                  onError: (e) => print("Error getting document: $e"),
                );
              }
              
              
            },
            child: Text('test'),
          ),
          const TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Start Date',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> uploadFile(final uid) async {
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final fileName = result!.files.single.name;
    print(fileName);
    final filePath = result.files.single.path;
    final file = File(filePath!);
    final fileBytes = File(result.files.single.path!).readAsBytesSync();

    final metadate = SettableMetadata(contentType: 'json');
    final storageRef = FirebaseStorage.instance.ref();
    final uploadTask = storageRef.child("Files/$uid/watch-history.json").putFile(file, metadate);

    // Listen for state changes, errors, and completion of the upload.
    uploadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot) {
      switch (taskSnapshot.state) {
        case TaskState.running:
          final progress =
              100.0 * (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes);
          print("Upload is $progress% complete.");
          break;
        case TaskState.paused:
          print("Upload is paused.");
          break;
        case TaskState.canceled:
          print("Upload was canceled");
          break;
        case TaskState.error:
          // Handle unsuccessful uploads
          break;
        case TaskState.success:
          // Handle successful uploads on complete
          // ...
          break;
      }
    });
  }

  Future<void> sendCommand(bool handleFile, String userUid) async {
    print('1111111111');
    // final url = Uri.parse('https://sms-app-project-415923.nw.r.appspot.com/api/handle_file');
    final url = Uri.parse('http://localhost:5000/api/handle_file');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "handle_file": handleFile,
        "userUid": userUid,
      }),
    );
    print('22222');
    print(response.statusCode);
    if (response.statusCode == 200) {
      print('Response from server: ${response.body}');
    } else {
      print('Failed to send command.');
    }
  }

  Future<void> handleData(bool handleData, String userUid, String startDate, String endDate) async {
    print('77777');
    // final url = Uri.parse('https://sms-app-project-415923.nw.r.appspot.com/api/handle_data');
    final url = Uri.parse('http://localhost:5000/api/handle_data');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "handle_data": handleData,
        "userUid": userUid,
        "startDate": startDate,
        "endDate": endDate,
      }),
    );
    print('88888');
    print(response.statusCode);
    if (response.statusCode == 200) {
      print('Response from server: ${response.body}');
    } else {
      print('Failed to send command.');
    }
  }

}

