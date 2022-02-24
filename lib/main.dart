import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:gobble/words.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final List<String> words = (await loadWords()).split('\n');
  for(int i = 0; i < words.length; i++) {
    words[i] = words[i].toLowerCase();
  }
  words.sort();
  print(words.length);
  runApp(MyApp(words,prefs));
}

Future<String> loadWords() async {
  // return await rootBundle.loadString('Words.txt');
  return wordsStr;
}

class MyApp extends StatelessWidget {
  MyApp(this.words,this.prefs,{Key? key}) : super(key: key);
  final List<String> words;
  SharedPreferences prefs;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gobble',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        textTheme: GoogleFonts.latoTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme, // If this is not set, then ThemeData.light().textTheme is used.
        ),
      ),
      home: Home(words,prefs),
    );
  }
}

class Home extends StatefulWidget {
  Home(this.words,this.prefs,{ Key? key }) : super(key: key);
  List<String> words;
  SharedPreferences prefs;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int gridSize = 8;
  late List<String?> grid;

  List<String> letters = "abcdefghijklmnopqrstuvwxyz".split("");

  List<double> weights = [
    0.08457883369330453, 0.10885529157667387,
    0.1500647948164147, 0.18401727861771058,
    0.29053995680345573, 0.31041036717062637,
    0.33727861771058315, 0.37088552915766737,
    0.42885529157667385, 0.43118790496760256,
    0.44933045356371487,  0.5114470842332614,
    0.5387473002159827,  0.5884233261339092,
    0.6535637149028077,  0.6852699784017278,
    0.6877753779697623,  0.7654427645788335,
    0.8232397408207341,  0.8862203023758097,
    0.9265658747300214,  0.9397840172786175,
      0.956630669546436,  0.9598272138228939,
    0.9965442764578831,  1.0
  ];

  void save(){
    widget.prefs.setStringList('save_grid', grid.map( (s) => s ?? "0").toList());
    widget.prefs.setStringList("save_nextLetters", nextLetters);
    widget.prefs.setInt("save_score", score);
  }

  int score = 0;

  String chooseLetter(){
    double rand = Random().nextDouble();
    int i = 0;
    while(rand > weights[i] && i<letters.length){
      i++;
    }
    return letters[i];
  }

  late List<String> nextLetters;

  Future<void> _showMyDialog() async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Gobble: An 8x8 Grid Word Game',
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        
        textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: const <Widget>[
              Text(
                'How To Play',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold,),
                textAlign: TextAlign.center,
                ),
              Text('1. You Will Be Given A Letter To Place In The Grid',
              style: TextStyle(fontSize: 15),
              ),
              Text('2. Place The Letter In A Grid Space',
              style: TextStyle(fontSize: 15),
              ),
              Text('3. Create 4 and 5 letter words to remove letters from the grid',
              style: TextStyle(fontSize: 15),
              ),
              Text('4. Play until you fill up your grid',
              style: TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
           style: TextButton.styleFrom(
    primary: Colors.greenAccent, // Text Color
  ),
            child: const Text('Begin',
            style: TextStyle(fontSize: 20),
            ),
            
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

  @override
  void initState() {
    super.initState();
    grid = List.filled(gridSize*gridSize, null);
    if(widget.prefs.getStringList("save_grid") !=null){
      List<String> tempGrid = widget.prefs.getStringList("save_grid") ?? [];
      if(tempGrid.length == gridSize * gridSize){
        grid = tempGrid.map((s) => s=="0" ? null : s).toList();
      }
    }
    score = widget.prefs.getInt("save_score") ?? 0;
    nextLetters = widget.prefs.getStringList("save_nextLetters") ?? [];
    if(nextLetters.length!=3){
      nextLetters = [chooseLetter(), chooseLetter(), chooseLetter()];
    }

    int highScore = widget.prefs.getInt("highScore") ?? 0;
    if(highScore==0){
      SchedulerBinding.instance?.addPostFrameCallback((_) => _showMyDialog());
    }

  }

  List<FoundWord> findLen(int targetSize){
    List<FoundWord> foundWords = [];
    for(int i=0; i<gridSize; i++){
      for(int j=0; j<gridSize-targetSize+1; j++){
        //Words in row;
        List<String?> letters = grid.sublist(i*gridSize+j, i*gridSize+j+targetSize);
        if(!letters.contains(null)){
          String word = letters.join();
          if(widget.words.contains(word)){
            print("FOUND: $word");
            foundWords.add(FoundWord(true,word, i*gridSize+j, i*gridSize+j+targetSize));
          }
        }

        //Words in column;
        letters = List.generate(targetSize, (k) => grid[(j+k)*gridSize + i]);
        if(!letters.contains(null)){
          String word = letters.join();
          if(widget.words.contains(word)){
            print("FOUND: $word");
            foundWords.add(FoundWord(false,word, j*gridSize+i, (j+targetSize)*gridSize + i));
          }
        }
      }
    }
    return foundWords;
  }

  void findWords(){
    List<FoundWord> foundWords = [...findLen(4),...findLen(5)];
    if(foundWords.isEmpty){
      save();
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

    save();
    // SnackBar snackBar = SnackBar(
    //   content: Text('You spelled: ${foundWords.map((f) => f.word).join(", ")}'),
    //   duration: const Duration(milliseconds: 2500),
    // );
    // ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  bool showedLoseDialog = false;

  void checkLoss(){
    if(grid.contains(null) || showedLoseDialog){
      return;
    }
    showedLoseDialog = true;
    widget.prefs.remove("save_grid");
    widget.prefs.remove("save_nextLetters");
    widget.prefs.remove("save_score");
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
                  nextLetters.removeAt(0);
                  nextLetters.add(chooseLetter());
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
        leading:IconButton(onPressed: _showMyDialog, icon: Icon(Icons.help)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(child: Text("High score: ${widget.prefs.getInt("highScore") ?? 0}", style: Theme.of(context).textTheme.headline6,)),
          ),
        ],
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
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, BoxConstraints constraints) {
                    double size = max(min(min(constraints.maxWidth,
                           constraints.maxHeight),600),150);
                    return SizedBox(
                      width: size,
                      height: size,
                      child: GridView.count(
                        crossAxisCount: gridSize,
                        children: [
                          for(int i=0; i<grid.length; i++)
                            WordTile(grid[i],size/12,(){
                              if(grid[i]!=null){
                                return;
                              }
                              setState(() {
                                grid[i] = nextLetters.removeAt(0);
                                score++;
                                if(score>(widget.prefs.getInt("highScore") ?? 0)){
                                  widget.prefs.setInt("highScore", score);
                                }
                                nextLetters.add(chooseLetter());
                                findWords();
                              });
                            }),
                        ],
                      )
                    );
                  }
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    nextLetters.first.toUpperCase(),
                    style: Theme.of(context).textTheme.headline2,
                  ),
                  Container(width:10),
                  Text(
                    nextLetters[1].toUpperCase(),
                  ),
                  Container(width:10),
                  Text(
                    nextLetters[2].toUpperCase(),
                  ),
                ],
              ),
            ),
            
          ],
        ),
      )
    );
  }
}

class WordTile extends StatelessWidget {
  const WordTile(this.letter,this.fontSize,this.onTap);
  final String? letter;
  final double fontSize;
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
          child: Text(letter?.toUpperCase() ?? "", style: TextStyle(fontSize: fontSize)),
        ),
      ),
    ); 
  }
}

class FoundWord{
  FoundWord(this.row,this.word,this.start,this.end);
  final bool row;
  final String word;
  final int start;
  final int end;
}