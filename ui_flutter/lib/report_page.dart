
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
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'src/authentication.dart';
import 'src/widgets.dart';

import 'chart_page.dart';

final db = FirebaseFirestore.instance;

class ReportPage extends StatefulWidget {
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  // const ReportPage({super.key});
  DateTime selectedDate = DateTime.now();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    // final appState = Provider.of<ApplicationState>(context);
    // final uid = appState.userUid;
    // final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report'),
      ),
      body: ListView(
        children: <Widget>[
          Text('Upload Your YouTube Watching History and View Your Online Behaviours\' Report Here'),
          Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outlined),
                  Text('Instructions'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.question_mark),
                  TextButton(
                    onPressed: () => _showInstructionDialog(context),
                    child: Text('How to download YouTube history'),
                  ),
                ],
              ),
              
              
            ],
          ),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                await uploadFile(FirebaseAuth.instance.currentUser!.uid);
                print('File uploaded');
                
                await processFile(true, FirebaseAuth.instance.currentUser!.uid);
                print('working');
                
                setState(() {
                  _isUploading = false;
                });
              }, 
              child: Text('Upload File'),
            ),
          ),
          if (_isUploading)
            Center(
              child: SpinKitCircle(
                color: Colors.blue,
                duration: Duration(milliseconds: 3000),
                size: 100.0,
              ),
            ),
          SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                DateTime now = DateTime.now();
                DateTime startLastWeek = DateTime(now.year, now.month, now.day - 6, 0, 0, 0);
                DateTime endToday = DateTime(now.year, now.month, now.day);
            
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
              child: Text('View Report'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> uploadFile(final uid) async {
    
    setState(() {
      _isUploading = true;
    });

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: true,
    );

    final storageRef = FirebaseStorage.instance.ref();
    UploadTask? uploadTask;
      
    if (kIsWeb) {
      PlatformFile file = result!.files.first;
      
      String fileName = file.name;
      // Use bytes property for web
      Uint8List? fileBytes = file.bytes;
      
      // Do something with the uploaded file bytes and name
      if (fileBytes != null) {
        uploadTask = storageRef.child("Files/$uid/$fileName").putData(fileBytes);

      } else {
        print('No file selected or file is empty');
      }
    } else {
      final fileName = result!.files.single.name;
      print(fileName);
      final filePath = result.files.single.path;
      final file = File(filePath!);
      // final fileBytes = File(result.files.single.path!).readAsBytesSync();

      final metadate = SettableMetadata(contentType: 'json');
      
      uploadTask = storageRef.child("Files/$uid/watch-history.json").putFile(file, metadate);

      
    }
    
    // Listen for state changes, errors, and completion of the upload.
    uploadTask!.snapshotEvents.listen((TaskSnapshot taskSnapshot) {
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
          print('Upload failed');
          showHint(context, 'Upload Failed!');
          break;
        case TaskState.success:
          // Handle successful uploads on complete
          print('Upload succeed');
          // setState(() {
          //   _isUploading = false;
          // });
          showHint(context, 'Upload Succeed!');
          break;
      }
    });
  }

  void showHint(BuildContext context, String message) {
    // 显示Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> processFile(bool handleFile, String userUid) async {
    
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
      showHint(context, 'Ready To View Your Report!');
    } else {
      print('Failed to send command.');
      showHint(context, 'Failed to process the file...');
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

  void _showInstructionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Instructions'),
          content: Column(
            children: [
              Text('How to download YouTube history'),
              Text('1. Search Google Takeout'),
              Text('2. Select YouTube'),
              Text('3. Download the file in JSON format'),
            ],
          ),
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
}

