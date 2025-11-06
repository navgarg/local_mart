import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginDevPage extends StatefulWidget {
  const LoginDevPage({super.key});

  @override
  State<LoginDevPage> createState() => _LoginDevPageState();
}

class _LoginDevPageState extends State<LoginDevPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> login() async {
    setState(() { loading = true; error = null; });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/cart');
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dev Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: "Password")),
            const SizedBox(height: 20),
            if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: loading ? null : login,
              child: Text(loading ? "Logging in..." : "Login"),
            ),
          ],
        ),
      ),
    );
  }
}
