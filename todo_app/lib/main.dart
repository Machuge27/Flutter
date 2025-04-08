import 'package:flutter/material.dart';
import 'login_page.dart';
import 'todo_page.dart';
import 'pages/main_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do & Note App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'pt mono', //roboto
        appBarTheme: AppBarTheme(centerTitle: true),
      ),  
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        // '/todo': (context) => TodoPage(),
        '/todo': (context) => MainPage(),
      },
    );
  }
}


