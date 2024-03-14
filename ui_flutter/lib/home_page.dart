import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'app_state.dart';
import 'file_upload.dart';
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
              FileUpload fileUpload = FileUpload();
              fileUpload.uploadFile();
            }, 
            child: Text('Upload File'),
          )
        ],
      ),
    );
  }

  }