import 'package:flutter/material.dart';

class Write extends StatelessWidget {
  static const id = 'write';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 5.0,
        title: Text(
          '오늘뭐먹지?',
          style: TextStyle(color: Colors.black45),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_outlined,
            color: Colors.black54,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
