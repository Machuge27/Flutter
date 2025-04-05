import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Login", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(height: 30),
              TextField(
                controller: _username,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Dummy login - navigate to ToDo screen
                  Navigator.pushReplacementNamed(context, '/todo');
                },
                child: Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
