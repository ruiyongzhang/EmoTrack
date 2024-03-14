import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

class FileUpload {
  final mainReference = FirebaseDatabase.instance.reference().child('Database');

  Future<void> uploadFile() async {
    
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
    final uploadTask = storageRef.child("Files/watch-history.json").putFile(file, metadate);

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