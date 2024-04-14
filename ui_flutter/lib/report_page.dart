
import 'dart:io';
import 'package:flutter/cupertino.dart';
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
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'src/authentication.dart';
import 'src/widgets.dart';

import 'chart_page.dart';

final db = FirebaseFirestore.instance;

class ReportPage extends StatelessWidget {
  // const ReportPage({super.key});
  DateTime selectedDate = DateTime.now();

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
              await sendCommand(true, FirebaseAuth.instance.currentUser!.uid);
              print('working');
            }, 
            child: Text('Upload File'),
          ),
          ElevatedButton(
            onPressed: () {
              DateTime now = DateTime.now();
              DateTime startLastWeek = DateTime(now.year, now.month, now.day - 6, 0, 0, 0);
              DateTime endToday = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);

              String lastWeekStartDay = startLastWeek.toString().substring(0, 19);
              String endTodayDay = endToday.toString().substring(0, 19);
              print(lastWeekStartDay);
              print(endTodayDay);
              handleData(true, FirebaseAuth.instance.currentUser!.uid, lastWeekStartDay, endTodayDay);
              
            },
            child: Text('Report Generation'),
          ),
          ElevatedButton(
            onPressed: () async {
              DateTime now = DateTime.now();
              DateTime startLastWeek = DateTime(now.year, now.month, now.day - 6, 0, 0, 0);
              DateTime endToday = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);

              String lastWeekStartDay = startLastWeek.toString().substring(0, 19);
              String endTodayDay = endToday.toString().substring(0, 19);

              await handleData(true, FirebaseAuth.instance.currentUser!.uid, lastWeekStartDay, endTodayDay);
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
        ],
      ),
    );
  }

  void _showCupertinoDatePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: MediaQuery.of(context).copyWith().size.height / 3,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.dateAndTime, // 你可以选择日期(date)、时间(time)或日期和时间(dateAndTime)
            onDateTimeChanged: (DateTime newDate) {
              // 这里处理日期时间变更事件
              print(newDate);
              selectedDate = newDate;
              
            },
            initialDateTime: DateTime.now(),
            minimumYear: 2000,
            maximumYear: DateTime.now().year,
            use24hFormat: true, // 是否使用24小时格式
          ),
        );
      },
    );
  }

  Future<void> uploadFile(final uid) async {
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      final storageRef = FirebaseStorage.instance.ref();

      if (kIsWeb) {
        // Use bytes property for web
        Uint8List? fileBytes = file.bytes;
        String fileName = file.name;
        // Do something with the uploaded file bytes and name
        if (fileBytes != null) {
          final uploadTask = storageRef.child("Files/$uid/watch-history.json").putData(fileBytes);

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
        } else {
          print('No file selected or file is empty');
        }
      } else {
        final fileName = result!.files.single.name;
        print(fileName);
        final filePath = result.files.single.path;
        final file = File(filePath!);
        final fileBytes = File(result.files.single.path!).readAsBytesSync();

        final metadate = SettableMetadata(contentType: 'json');
        
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
    } else {
      // User canceled the picker
      print('User Cancelled Upload');
    }
    

    

    
  }

  Future<void> sendCommand(bool handleFile, String userUid) async {
    print('1111111111');
    final url = Uri.parse('https://sms-app-project-415923.nw.r.appspot.com/api/handle_file');
    // final url = Uri.parse('http://localhost:5000/api/handle_file');
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
    final url = Uri.parse('https://sms-app-project-415923.nw.r.appspot.com/api/handle_data');
    // final url = Uri.parse('http://localhost:5000/api/handle_data');
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

