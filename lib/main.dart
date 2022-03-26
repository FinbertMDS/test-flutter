
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/grpc/helloworld/hello_world.pbgrpc.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'ホーム画面'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _textValue = "";

  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("入力した文字"),
          content: new Text(_textValue),
          actions: <Widget>[
            new TextButton(
              child: new Text("閉じる"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _gotoSecondPage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) {
      return SecondPage();
    }));
  }

  void _gotoThirdPage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) {
      return ThirdPage();
    }));
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style =
        ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ConstrainedBox(
              constraints: BoxConstraints.tight(const Size(300, 70)),
              child: TextFormField(
                decoration: const InputDecoration(
                  hintText: '入力する',
                ),
                onChanged: (text) {
                  setState(() {
                    _textValue = text;
                  });
                },
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: style,
              onPressed: _showDialog,
              child: const Text('OK'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: style,
              onPressed: _gotoSecondPage,
              child: const Text('画面２に遷移する'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: style,
              onPressed: _gotoThirdPage,
              child: const Text('画面３に遷移する'),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondPage extends StatefulWidget {
  const SecondPage({Key? key}) : super(key: key);

  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  late Future<Album> futureAlbum;

  Future<Album> fetchAlbum() async {
    final response = await http
        .get(Uri.parse('https://jsonplaceholder.typicode.com/albums/1'));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return Album.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
  }

  @override
  void initState() {
    super.initState();
    futureAlbum = fetchAlbum();
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style =
        ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));

    return Scaffold(
      appBar: AppBar(
        title: Text('画面２'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<Album>(
              future: futureAlbum,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(snapshot.data!.title);
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                }

                // By default, show a loading spinner.
                return CircularProgressIndicator();
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: style,
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ホーム画面に戻る'),
            ),
          ],
        ),
      ),
    );
  }
}

class Album {
  final int userId;
  final int id;
  final String title;

  Album({
    required this.userId,
    required this.id,
    required this.title,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      userId: json['userId'],
      id: json['id'],
      title: json['title'],
    );
  }
}

class ThirdPage extends StatefulWidget {
  const ThirdPage({Key? key}) : super(key: key);

  @override
  _ThirdPageState createState() => _ThirdPageState();
}

class _ThirdPageState extends State<ThirdPage> {
  late Future<String> futureSayHello;

  Future<String> sayHello() async {
    final channel = ClientChannel(
      '127.0.0.1',
      port: 50051,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    final stub = GreeterClient(channel);

    final name = 'hello';

    String result = '';
    try {
      var response = await stub.sayHello(HelloRequest()..name = name);
      print('Greeter client received: ${response.message}');
      result = response.message;
    } catch (e) {
      print('Caught error: $e');
    }
    await channel.shutdown();

    return result;
  }

  @override
  void initState() {
    super.initState();
    futureSayHello = sayHello();
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style =
        ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));

    return Scaffold(
      appBar: AppBar(
        title: Text('画面３'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<String>(
              future: futureSayHello,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(snapshot.data!);
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                }

                // By default, show a loading spinner.
                return CircularProgressIndicator();
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: style,
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ホーム画面に戻る'),
            ),
          ],
        ),
      ),
    );
  }
}