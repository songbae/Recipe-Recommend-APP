import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:recipe_app/changeDate.dart';
import 'package:recipe_app/infoPage.dart';
import 'package:recipe_app/initPage.dart';
import 'package:recipe_app/mainPage.dart';
import 'package:recipe_app/write.dart';
import 'package:recipe_app/animatedStartingPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [GlobalMaterialLocalizations.delegate],
      supportedLocales: [Locale('en'), Locale('kr')],
      initialRoute: AnimatedStartingPage.id,
      routes: {
        InitPage.id: (context) => InitPage(),
        InfoPage.id: (context) => InfoPage(),
        MainPage.id: (context) => MainPage(),
        ChangeDate.id: (context) => ChangeDate(),
        Write.id: (context) => Write(),
        AnimatedStartingPage.id: (context) => AnimatedStartingPage(),
      },
    );
  }
}
