import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gobble/words.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final List<String> words = (await loadWords()).split('\n');
  words.sort();
  print(words.length);
  runApp(MyApp(words));
}

Future<String> loadWords() async {
  // return await rootBundle.loadString('Words.txt');
  return wordsStr;
}

class MyApp extends StatelessWidget {
  MyApp(this.words,{Key? key}) : super(key: key);
  final List<String> words;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
      ),
      home: Home(words),
    );
  }
}

class Home extends StatefulWidget {
  Home(this.words,{ Key? key }) : super(key: key);
  List<String> words;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int gridSize = 8;
  late List<String?> grid;

  List<String> consanants = "bcdfghklmnprstvwy".split("");
  List<String> uncommon = "jqxz".split("");
  List<String> vowels = "aeiou".split("");

  int score = 0;

  String chooseLetter(){
    double chanceVowel = 0.3;
    double rand = Random().nextDouble();
    if(rand < chanceVowel){
      return vowels[Random().nextInt(vowels.length)];
    }
    if(rand < chanceVowel + 0.05){
      return uncommon[Random().nextInt(uncommon.length)];
    }
    return consanants[Random().nextInt(consanants.length)];
    // if(score%5 == 4){
    //   return vowels[Random().nextInt(vowels.length)];
    // }
    // return consanants[Random().nextInt(consanants.length)];
  }

  late String nextLetter;

  @override
  void initState() {
    super.initState();
    nextLetter = chooseLetter();
    grid = List.filled(gridSize*gridSize, null);;
  }

  void findWords(){
    List<FoundWord> foundWords = [];
    print("FINDING WORDS");
    int targetSize = 5;
    for(int i=0; i<gridSize; i++){
      for(int j=0; j<gridSize-targetSize+1; j++){
        //Words in row;
        List<String?> letters = grid.sublist(i*gridSize+j, i*gridSize+j+targetSize);
        if(!letters.contains(null)){
          String word = letters.join();
          if(widget.words.contains(word)){
            print("FOUND: $word");
            foundWords.add(FoundWord(true, i*gridSize+j, i*gridSize+j+targetSize));
          }
        }

        //Words in column;
        letters = List.generate(targetSize, (k) => grid[(j+k)*gridSize + i]);
        if(!letters.contains(null)){
          String word = letters.join();
          if(widget.words.contains(word)){
            print("FOUND: $word");
            foundWords.add(FoundWord(false, j*gridSize+i, (j+targetSize)*gridSize + i));
          }
        }
      }
    }
    if(foundWords.isEmpty){
      checkLoss();
      return;
    }
    setState(() {
      for(FoundWord found in foundWords){
        if(found.row){
          for(int i=found.start; i<found.end; i++){
            grid[i] = null;
          }
        }
        else{
          for(int i=found.start; i<found.end; i+=gridSize){
            grid[i] = null;
          }
        }
      }
    });
  }

  bool showedLoseDialog = false;

  void checkLoss(){
    if(grid.contains(null) || showedLoseDialog){
      return;
    }
    showedLoseDialog = true;
    showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: const Text("You Lose!"),
          content: Text("Your score is $score"),
          actions: <Widget>[
            TextButton(
              child: const Text("Play Again"),
              onPressed: (){
                Navigator.of(context).pop();
                setState(() {
                  showedLoseDialog = false;
                  score = 0;
                  grid = List.filled(gridSize*gridSize, null);
                  nextLetter = chooseLetter();
                });
              },
            ),
          ],
        );
      }
    );
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
                  crossAxisCount: gridSize,
                  children: [
                    for(int i=0; i<grid.length; i++)
                      WordTile(grid[i],(){
                        if(grid[i]!=null){
                          return;
                        }
                        setState(() {
                          grid[i] = nextLetter;
                          score++;
                          nextLetter = chooseLetter();
                          findWords();
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

class FoundWord{
  FoundWord(this.row,this.start,this.end);
  final bool row;
  final int start;
  final int end;
}