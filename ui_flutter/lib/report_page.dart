import 'dart:ffi';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'app_state.dart';

import 'src/authentication.dart';
import 'src/widgets.dart';

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
            onPressed: (){
              uploadFile(FirebaseAuth.instance.currentUser!.uid);
            }, 
            child: Text('Upload File'),
          ),
          ElevatedButton(
            onPressed: (){
              sendCommand(true);
              print('working');
            }, 
            child: Text('Working...'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChartPage())
              );
            },
            child: Text('Generate Your Viewing Behaviours Report'),
          )
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
    final uploadTask = storageRef.child("Files/$uid/$fileName").putFile(file, metadate);

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

  Future<void> sendCommand(bool handleFile) async {
    print('1111111111');
    final url = Uri.parse('https://sms-app-project-415923.nw.r.appspot.com/api/handle_file');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"handle_file": handleFile}),
    );
    print('22222');
    print(response.statusCode);
    if (response.statusCode == 200) {
      print('Response from server: ${response.body}');
    } else {
      print('Failed to send command.');
    }
  }

}

class ChartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Viewing Behaviours Report'),
      ),
      body: Center(
        child: Text('This is the Viewing Behaviours Report Page'),
      ),
      
    );
  }
}