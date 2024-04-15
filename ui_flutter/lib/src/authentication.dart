// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets.dart';

class AuthFunc extends StatelessWidget {
  const AuthFunc({
    super.key,
    required this.loggedIn,
    required this.signOut,
  });

  final bool loggedIn;
  final void Function() signOut;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        widthFactor: 12.0,
        heightFactor: 12.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              verticalDirection: VerticalDirection.up,
              children: [
                StyledButton(
                  onPressed: () {
                    !loggedIn ? context.push('/sign-in') : signOut();
                  },
                  child: !loggedIn ? const Text('Enter EmoTrack') : const Text('Logout')
                ),
                Visibility(
                  visible: loggedIn,
                  child: Row(
                    children: [
                      SizedBox(width: 30),
                      StyledButton(
                          onPressed: () {
                            context.push('/profile');
                          },
                          child: const Text('Profile')),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
