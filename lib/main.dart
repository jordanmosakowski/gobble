import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:gobble/words.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final Map<int,List<String>> words = {
    4: (await loadWords(4)).split('\n'),
    5: (await loadWords(5)).split('\n'),
    6: (await loadWords(6)).split('\n'),
    7: (await loadWords(7)).split('\n'),
    8: (await loadWords(8)).split('\n'),
  };
  print(words.length);
  runApp(MyApp(words,prefs));
}

Future<String> loadWords(int len) async {
  // return await rootBundle.loadString('Words.txt');
  if(kDebugMode){
    return await rootBundle.loadString('$len.txt');
  }
  return await rootBundle.loadString('assets/$len.txt');
}

class MyApp extends StatelessWidget {
  MyApp(this.words,this.prefs,{Key? key}) : super(key: key);
  final Map<int,List<String>> words;
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
  Map<int,List<String>> words;
  SharedPreferences prefs;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int gridSize = 7;
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
        title: const Text('Gobble: An 7x7 Grid Word Game',
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
              Text('3. Create 4+ Letter Words To Remove Letters From The Grid',
              style: TextStyle(fontSize: 15),
              ),
              Text('4. Only Top Bottom And Left To Right',
              style: TextStyle(fontSize: 15),
              ),
              Text('5. Play until you fill up your grid',
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

Future<void> showResetDialog() async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Are You Sure You Want To Reset?',
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        
        textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: const <Widget>[
              Text(
                'Your Score Will Be Set To Zero',
                style: TextStyle(fontSize: 25,),
                textAlign: TextAlign.center,
                ),
              
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
           style: TextButton.styleFrom(
    primary: Colors.yellowAccent, // Text Color
  ),
            child: const Text('Reset',
            style: TextStyle(fontSize: 20),
            ),
            
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                score = 0;
                grid = List.filled(gridSize*gridSize, null);
                nextLetters = [chooseLetter(), chooseLetter(), chooseLetter()];
                widget.prefs.remove("save_grid");
                widget.prefs.remove("save_nextLetters");
                widget.prefs.remove("save_score");
              });
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
    score = widget.prefs.getInt("save_score") ?? 0;
    nextLetters = widget.prefs.getStringList("save_nextLetters") ?? [];
    if(widget.prefs.getStringList("save_grid") !=null){
      List<String> tempGrid = widget.prefs.getStringList("save_grid") ?? [];
      if(tempGrid.length == gridSize * gridSize){
        grid = tempGrid.map((s) => s=="0" ? null : s).toList();
      }
      else{
        score = 0;
        nextLetters = [];
      }
    }
    if(nextLetters.length!=3){
      nextLetters = [chooseLetter(), chooseLetter(), chooseLetter()];
    }

    int highScore = widget.prefs.getInt("highScore") ?? 0;
    if(highScore==0){
      SchedulerBinding.instance?.addPostFrameCallback((_) => _showMyDialog());
    }
    findWords();
  }

  List<FoundWord> findLen(int targetSize){
    List<FoundWord> foundWords = [];
    for(int i=0; i<gridSize; i++){
      for(int j=0; j<gridSize-targetSize+1; j++){
        //Words in row;
        List<String?> letters = grid.sublist(i*gridSize+j, i*gridSize+j+targetSize);
        if(!letters.contains(null)){
          String word = letters.join();
          if(wordSearch(widget.words[targetSize] ?? [],word)){
            print("FOUND: $word");
            foundWords.add(FoundWord(true,word, i*gridSize+j, i*gridSize+j+targetSize));
          }
        }

        //Words in column;
        letters = List.generate(targetSize, (k) => grid[(j+k)*gridSize + i]);
        if(!letters.contains(null)){
          String word = letters.join();
          if(wordSearch(widget.words[targetSize] ?? [],word)){
            print("FOUND: $word");
            foundWords.add(FoundWord(false,word, j*gridSize+i, (j+targetSize)*gridSize + i));
          }
        }
      }
    }
    return foundWords;
  }

  bool wordSearch(List<String> arr, word){
    int low = 0;
    int high = arr.length-1;
    while(low<=high){
      int mid = ((low+high)/2).floor();
      if(arr[mid]==word){
        return true;
      }
      if(arr[mid].compareTo(word)>0){
        high = mid-1;
      }else{
        low = mid+1;
      }
    }
    return false;
  }

  void findWords(){
    List<FoundWord> foundWords = [...findLen(4),...findLen(5),...findLen(6),...findLen(7)];
    if(foundWords.isEmpty){
      save();
      checkLoss();
      return;
    }
    for(FoundWord found in foundWords){
      if(found.word.length>4){
        score += (found.word.length-3);
      }
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
                  nextLetters = [chooseLetter(), chooseLetter(), chooseLetter()];
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
        leading:IconButton(onPressed: _showMyDialog, icon: const Icon(Icons.help)),
        actions: [
          IconButton(onPressed: showResetDialog, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Score: $score",
              style: Theme.of(context).textTheme.headline4!.copyWith(
                color: Colors.white
              ),
            ),
            Center(child: Text("High score: ${widget.prefs.getInt("highScore") ?? 0}", style: Theme.of(context).textTheme.headline6!.copyWith(
              color: Colors.white70
            ),)),
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
                                nextLetters.add(chooseLetter());
                                findWords();
                                if(score>(widget.prefs.getInt("highScore") ?? 0)){
                                  widget.prefs.setInt("highScore", score);
                                }
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Text(
              letter?.toUpperCase() ?? "", style: TextStyle(fontSize: fontSize),
              key: ValueKey<String>(letter ?? ""),
            )
          ),
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