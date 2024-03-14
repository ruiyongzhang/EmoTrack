import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'app_state.dart';
import 'src/authentication.dart';
import 'src/widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: ListView(
        children: <Widget>[
          const Header('Upload Your YouTube Watching History Here'),
          ElevatedButton(
            onPressed: (){
              uploadFile();
            }, 
            child: Text('Upload File'),
          )
        ],
      ),
    );
  }

  Future<void> uploadFile() async {
    final storage = FirebaseStorage.instance;
    final storageRef = FirebaseStorage.instance.ref();
    Reference? fileRef = storageRef.child("json");
    final fileName = "watch-history.json";
    final spaceRef = fileRef.child(fileName);
    final path = spaceRef.fullPath;
    final name = spaceRef.name;
    fileRef = spaceRef.parent;

    final appDocDir = await getApplicationDocumentsDirectory();
    final filePath = "${appDocDir.absolute}/watch-history.json";
    final file = File(filePath);
    final metadata = SettableMetadata(contentType: 'json');

    final uploadTask = storageRef
                        .child("files/watch-history.json")
                        .putFile(file, metadata);
    
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
}