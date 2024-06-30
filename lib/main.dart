import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';
import 'package:linkify/linkify.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scam Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Montserrat',
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MessageChecker()),
      );
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Scam Scanner',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageChecker extends StatefulWidget {
  @override
  _MessageCheckerState createState() => _MessageCheckerState();
}

class _MessageCheckerState extends State<MessageChecker> {
  final TextEditingController _controller = TextEditingController();
  String _result = '';
  int _validLinkChecks = 0;
  int _invalidLinkChecks = 0;
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin!.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body, int id) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'scam_link_channel',
      'Scam Link Notifications',
      channelDescription: 'Channel for scam link notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin!.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void _checkMessage(String message) {
    const List<String> keywords = [
      "kerajaan",
      "government",
      "Sumbangan",
      "Bantuan Kerajaan"
    ];

    bool hasKeywords = keywords.any((keyword) => message.contains(keyword));

    setState(() {
      _result = '';
    });

    if (hasKeywords) {
      List<String> links = _extractLinks(message);
      bool hasInvalidLink = false;
      for (String link in links) {
        if (!link.endsWith(".gov.my")) {
          _sendEmail(
              "gselva160@gmail.com",
              "Non-gov link detected",
              "The message contains a non-gov link: $link");
          _showNotification(
              "Scam Link Detected", "The message contains a non-gov link: $link", DateTime.now().millisecondsSinceEpoch);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("The message contains a non-gov link: $link"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );

          hasInvalidLink = true;
          setState(() {
            _invalidLinkChecks++;
            _result = 'Please be aware that this message has suspicious link. Do not enter your private credentials.';
          });
        }
      }
      if (!hasInvalidLink && links.isNotEmpty) {
        setState(() {
          _validLinkChecks++;
          _result = 'The message contains only valid government links: ${links.join(', ')}';
        });
      }
    } else {
      setState(() {
        _result = 'No keywords found in the message.';
      });
    }
  }

  List<String> _extractLinks(String message) {
    final elements = linkify(message);
    return elements
        .whereType<LinkableElement>()
        .map((element) => element.url)
        .toList();
  }

  Future<void> _sendEmail(String recipient, String subject, String body) async {
    const String username = 'selvagroot5@gmail.com';
    const String password = 'ppjw ugwq qaed hsrf';

    final smtpServer = gmail(username, password);

    final message = mailer.Message()
      ..from = mailer.Address(username, 'Selva')
      ..recipients.add(recipient)
      ..subject = subject
      ..text = body;

    try {
      final sendReport = await mailer.send(message, smtpServer);
      debugPrint('Message sent: ${sendReport.toString()}');
    } on mailer.MailerException catch (e) {
      debugPrint('Message not sent.');
      for (var p in e.problems) {
        debugPrint('Problem: ${p.code}: ${p.msg}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scam Scanner'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Scam Scanner Info"),
                    content: Text("This app helps you to detect potential scam messages by analyzing links and keywords."),
                    actions: [
                      TextButton(
                        child: Text("Close"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Enter the message to check for scams',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Enter your message',
                          hintText: 'Type your message here...',
                        ),
                        maxLines: 5,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _checkMessage(_controller.text),
                        icon: Icon(Icons.search),
                        label: Text('Check Message'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          textStyle: TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_result.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _result.contains('suspicious') ? Colors.red[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _result,
                    style: TextStyle(
                      fontSize: 16, 
                      color: _result.contains('suspicious') ? Colors.red : Colors.green
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              Divider(),
              Text(
                'Stats:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Valid link checks: $_validLinkChecks',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Invalid link checks: $_invalidLinkChecks',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
