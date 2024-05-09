
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
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
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    // final appState = Provider.of<ApplicationState>(context);
    // final uid = appState.userUid;
    // final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report',
          style: TextStyle(
            color: Color.fromRGBO(72, 61, 139, 1)
          ),
          ),
      ),
      body: ListView(
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 60, right: 50, top: 20, bottom: 20),
              child: Text(
                'After uploading your YouTube Watching History here, you can View your Online Behaviours\' Report!',
                style: TextStyle(
                  color: Color.fromRGBO(72, 61, 139, 0.7),
                  // fontSize: 10,
                )),
            ),
          ),
          Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outlined),
                  TextButton(
                    onPressed: () => _showInstructionDialog(context),
                    child: Text(
                      'Instructions',
                      style: TextStyle(
                        color: Color.fromRGBO(72, 61, 139, 0.9),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
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
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      children: [
                        Icon(Icons.upload_file, size: 55),
                        SizedBox(height: 5,),
                        Text('Upload File', style: TextStyle(fontSize: 15),),
                      ],
                    ),
                  ),
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
                  ),
                ),
              ),
              if (_isUploading)
                Center(
                  child: SpinKitCircle(
                    color: Colors.blue,
                    duration: Duration(seconds: 3),
                    size: 100.0,
                  ),
                ),
              SizedBox(height: 50),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _isGenerating = true;
                    });
                    DateTime now = DateTime.now();
                    DateTime startLastWeek = DateTime(now.year, now.month, now.day - 6, 0, 0, 0);
                    DateTime endToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
                
                    String lastWeekStartDay = startLastWeek.toString().substring(0, 19);
                    String endTodayDay = endToday.toString().substring(0, 19);
                
                    await handleData(true, FirebaseAuth.instance.currentUser!.uid, lastWeekStartDay, endTodayDay);
                    
                    setState(() {
                      _isGenerating = false;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChartPage(
                        startDate: startLastWeek,
                        endDate: endToday,
                      ))
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Column(
                      children: [
                        Icon(Icons.bar_chart_sharp, size: 60,),
                        SizedBox(height: 0),
                        Text('View Report'),
                      ],
                    ),
                  ),
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
                  ),
                ),
                
              ),
              if (_isGenerating)
                Center(
                  child: SpinKitCircle(
                    color: Colors.pink[300],
                    duration: Duration(seconds: 3),
                    size: 100.0,
                  ),
                ),
              
            ],
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
          title: Text('Instructions', textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. Download YouTube history:'),
                  Text('   - Search Google Takeout (https://takeout.google.com/settings/takeout)'),
                  Text('   - Select YouTube and "History"'),
                  Text('   - Choose JSON format, export and download'),
                  Text('2. Upload the file and wait for the report to be generated'),
                  Text('3. After it is loaded successfully, you can press the "View Report" button to view your report!'),
                ],
              ),
            ),
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

