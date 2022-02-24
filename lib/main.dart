import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({ Key? key }) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List<String?> grid = List.filled(8*8, null);

  List<String> consanants = "bcdfghjklmnpqrstvwxyz".split("");
  List<String> vowels = "aeiou".split("");

  int score = 0;

  String chooseLetter(){
    if(score%5 == 4){
      return vowels[Random().nextInt(vowels.length)];
    }
    return consanants[Random().nextInt(consanants.length)];
  }

  late String nextLetter;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    nextLetter = chooseLetter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gobble'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Score: $score",
              style: Theme.of(context).textTheme.headline4,
            ),
            Center(
              child: SizedBox(
                width: 500,
                height: 500,
                child: GridView.count(
                  crossAxisCount: sqrt(grid.length).toInt(),
                  children: [
                    for(int i=0; i<grid.length; i++)
                      WordTile(grid[i],(){
                        setState(() {
                          grid[i] = nextLetter;
                          score++;
                          nextLetter = chooseLetter();
                        });
                      }),
                  ],
                )
              ),
            ),
            Text(
              nextLetter.toUpperCase(),
              style: Theme.of(context).textTheme.headline2,
            ),
          ],
        ),
      )
    );
  }
}

class WordTile extends StatelessWidget {
  const WordTile(this.letter,this.onTap);
  final String? letter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    //container with white border with letter centered
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
        ),
        child: Center(
          child: Text(letter?.toUpperCase() ?? "", style: Theme.of(context).textTheme.headline3),
        ),
      ),
    ); 
  }
}