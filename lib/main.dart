import 'package:flutter/material.dart';

void main() {
  runApp(CricScorerApp());
}

class CricScorerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cric Scorer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SetupPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SetupPage extends StatefulWidget {
  @override
  _SetupPageState createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final team1Controller = TextEditingController();
  final team2Controller = TextEditingController();
  final oversController = TextEditingController(text: '5');
  final TextEditingController playersController = TextEditingController(text: '11');


  final _formKey = GlobalKey<FormState>();

  void proceedToToss() {
    if (_formKey.currentState!.validate()) {
      String team1 = team1Controller.text.trim();
      String team2 = team2Controller.text.trim();
      int overs = int.parse(oversController.text.trim());
      int players = int.parse(playersController.text.trim());

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TossPage(
            teamA: team1,
            teamB: team2,
            overs: overs,
            players: players,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    team1Controller.dispose();
    team2Controller.dispose();
    oversController.dispose();
    playersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cric Scorer Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildInputField(team1Controller, 'Team 1 Name'),
              buildInputField(team2Controller, 'Team 2 Name'),
              buildInputField(oversController, 'Overs (e.g. 5)', isNumber: true),
              buildInputField(playersController, 'Players per team (e.g. 11)', isNumber: true),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: proceedToToss,
                child: Text('Proceed to Toss'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInputField(TextEditingController controller, String labelText, {bool isNumber = false}) {
    return Column(
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: labelText),
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter $labelText';
            }
            if (isNumber) {
              int? val = int.tryParse(value.trim());
              if (val == null || val <= 0) {
                return 'Enter valid number';
              }
            }
            return null;
          },
        ),
        SizedBox(height: 10),
      ],
    );
  }
}

class TossPage extends StatefulWidget {
  final String teamA;
  final String teamB;
  final int overs;
  final int players;

  TossPage({required this.teamA, required this.teamB, required this.overs, required this.players});

  @override
  _TossPageState createState() => _TossPageState();
}

class _TossPageState extends State<TossPage> {
  String? selectedBattingTeam;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Toss')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Select batting team', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            RadioListTile<String>(
              title: Text(widget.teamA),
              value: widget.teamA,
              groupValue: selectedBattingTeam,
              onChanged: (value) {
                setState(() => selectedBattingTeam = value);
              },
            ),
            RadioListTile<String>(
              title: Text(widget.teamB),
              value: widget.teamB,
              groupValue: selectedBattingTeam,
              onChanged: (value) {
                setState(() => selectedBattingTeam = value);
              },
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (selectedBattingTeam == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select batting team')));
                  return;
                }
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScoringPage(
                      team1Name: widget.teamA,
                      team2Name: widget.teamB,
                      overs: widget.overs,
                      players: widget.players,
                      battingTeamSelected: selectedBattingTeam!,
                    ),
                  ),
                );
              },
              child: Text('Confirm'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ScoringPage and BallEvent will continue below in another chunk due to file size limits.


class BallEvent {
  final int runs;
  final bool isExtra;
  final String extraType;
  final bool countsAsBall;
  final String logText;

  BallEvent({
    required this.runs,
    this.isExtra = false,
    this.extraType = '',
    this.countsAsBall = true,
    required this.logText,
  });
}

class ScoringPage extends StatefulWidget {
  final String team1Name;
  final String team2Name;
  final int overs;
  final int players;
  final String battingTeamSelected;

  ScoringPage({
    required this.team1Name,
    required this.team2Name,
    required this.overs,
    required this.players,
    required this.battingTeamSelected,
  });

  @override
  _ScoringPageState createState() => _ScoringPageState();
}

class _ScoringPageState extends State<ScoringPage> {
  late String battingTeam;
  late String bowlingTeam;
  int innings = 1;
  int totalOvers = 0;
  int ballsInCurrentOver = 0;
  int totalBalls = 0;
  int runs = 0;
  int wickets = 0;
  int target = 0;
  int playersPerTeam = 11;
  List<String> ballLogs = [];
  List<BallEvent> undoStack = [];
  bool matchEnded = false;
  String resultText = '';

  @override
  void initState() {
    super.initState();
    totalOvers = widget.overs;
    playersPerTeam = widget.players;
    battingTeam = widget.battingTeamSelected;
    bowlingTeam = (battingTeam == widget.team1Name) ? widget.team2Name : widget.team1Name;
  }

  int get maxBalls => totalOvers * 6;
  bool get isAllOut => wickets >= playersPerTeam - 1;
  bool get isOverComplete => ballsInCurrentOver >= 6;

  void addBallLogWithCount(String log) {
    String overBallStr = "${(totalBalls ~/ 6)}.${ballsInCurrentOver + 1}";
    ballLogs.insert(0, "$overBallStr - $log");
    if (ballLogs.length > 10) ballLogs.removeLast();
  }

  void nextBall({bool isLegalBall = true}) {
    if (isLegalBall) {
      ballsInCurrentOver++;
      totalBalls++;
      if (isOverComplete) ballsInCurrentOver = 0;
    }
  }

  void checkInningsEnd() {
    if (innings == 1 && (totalBalls >= maxBalls || isAllOut)) {
      target = runs + 1;
      innings = 2;
      battingTeam = widget.team2Name;
      bowlingTeam = widget.team1Name;
      runs = 0;
      wickets = 0;
      totalBalls = 0;
      ballsInCurrentOver = 0;
      ballLogs.clear();
      addBallLogWithCount("Start of 2nd Innings. Target: $target runs");
    } else if (innings == 2) {
      if (runs >= target) {
        matchEnded = true;
        int wicketsLeft = playersPerTeam - 1 - wickets;
        resultText = "$battingTeam won by $wicketsLeft wicket${wicketsLeft == 1 ? '' : 's'}";
        addBallLogWithCount(resultText);
      } else if (isAllOut || totalBalls >= maxBalls) {
        matchEnded = true;
        if (runs == target - 1) {
          resultText = "Match Tied!";
        } else {
          int runsDiff = target - runs - 1;
          resultText = "$bowlingTeam won by $runsDiff run${runsDiff == 1 ? '' : 's'}";
        }
        addBallLogWithCount(resultText);
      }
    }
  }

  void addRuns(int run, {bool isExtra = false, String extraType = ''}) {
    if (matchEnded) return;
    setState(() {
      runs += run;
      String logText = isExtra ? "$extraType - $run run${run == 1 ? '' : 's'}" : "$run run${run == 1 ? '' : 's'}";
      addBallLogWithCount(logText);
      if (!isExtra) nextBall();
      undoStack.add(BallEvent(
        runs: run,
        isExtra: isExtra,
        extraType: extraType,
        countsAsBall: !isExtra,
        logText: logText,
      ));
      checkInningsEnd();
    });
  }

  void addWicket() {
    if (matchEnded) return;
    setState(() {
      wickets++;
      addBallLogWithCount("Wicket!");
      nextBall();
      undoStack.add(BallEvent(runs: 0, isExtra: false, extraType: "Wicket", countsAsBall: true, logText: "Wicket!"));
      checkInningsEnd();
    });
  }

  void addRunOut() async {
    int scoredRuns = await showExtraRunsDialog("Run Out");
    if (scoredRuns < 0) return;
    setState(() {
      if (scoredRuns > 0) runs += scoredRuns;
      wickets++;
      String logText = (scoredRuns == 0) ? "Run Out" : "Run Out - $scoredRuns run${scoredRuns == 1 ? '' : 's'}";
      addBallLogWithCount(logText);
      nextBall();
      undoStack.add(BallEvent(
        runs: scoredRuns,
        isExtra: true,
        extraType: "Run Out",
        countsAsBall: true,
        logText: logText,
      ));
      checkInningsEnd();
    });
  }

  void addWide() async {
    int extraRuns = await showExtraRunsDialog("Wide");
    if (extraRuns < 0) return;

    // Always add 1 run for the wide itself
    int totalRuns = extraRuns == 0 ? 1 : extraRuns + 1;

    setState(() {
      runs += totalRuns;
      String logText = "Wide - $totalRuns run${totalRuns == 1 ? '' : 's'}";
      addBallLogWithCount(logText);
      undoStack.add(BallEvent(
        runs: totalRuns,
        isExtra: true,
        extraType: "Wide",
        countsAsBall: false,
        logText: logText,
      ));
    });
  }


  void addNoBall() async {
    int extraRuns = await showExtraRunsDialog("No Ball");
    if (extraRuns < 0) return;

    // Always add 1 run for the no-ball itself
    int totalRuns = extraRuns == 0 ? 1 : extraRuns + 1;

    setState(() {
      runs += totalRuns;
      String logText = "No Ball - $totalRuns run${totalRuns == 1 ? '' : 's'}";
      addBallLogWithCount(logText);
      undoStack.add(BallEvent(
        runs: totalRuns,
        isExtra: true,
        extraType: "No Ball",
        countsAsBall: false,
        logText: logText,
      ));
    });
  }


  Future<int> showExtraRunsDialog(String extraName) async {
    TextEditingController extraController = TextEditingController(text: '1');
    int result = -1;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Enter runs for $extraName'),
        content: TextField(controller: extraController, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              int? val = int.tryParse(extraController.text.trim());
              result = (val == null || val < 0) ? 1 : val;
              Navigator.of(ctx).pop();
            },
            child: Text('OK'),
          )
        ],
      ),
    );
    return result;
  }

  void undoLastBall() {
    if (undoStack.isEmpty || matchEnded) return;
    setState(() {
      BallEvent last = undoStack.removeLast();
      runs = (runs - last.runs).clamp(0, runs);
      if (["Wicket", "Run Out"].contains(last.extraType)) {
        if (wickets > 0) wickets--;
      }
      if (last.countsAsBall) {
        if (ballsInCurrentOver == 0) {
          ballsInCurrentOver = 5;
          if (totalBalls > 0) totalBalls--;
        } else {
          ballsInCurrentOver--;
          totalBalls--;
        }
      }
      if (ballLogs.isNotEmpty) ballLogs.removeAt(0);
      matchEnded = false;
      resultText = "";
    });
  }

  String get oversDisplay => "${totalBalls ~/ 6}.${totalBalls % 6} / $totalOvers";
  int get ballsRemaining => maxBalls - totalBalls;
  String get runsNeeded => innings == 2 ? "${(target - runs).clamp(0, target)}" : "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Match Scoring'),
        actions: [
          IconButton(icon: Icon(Icons.flag), tooltip: 'End Match', onPressed: () {
            if (!matchEnded) {
              setState(() {
                matchEnded = true;
                resultText = innings == 1
                    ? "$battingTeam won by $runs run${runs == 1 ? '' : 's'}"
                    : "${bowlingTeam} won by ${(target - runs - 1).clamp(0, target)} run";
              });
            }
          }),
          IconButton(icon: Icon(Icons.undo), tooltip: 'Undo Last Ball', onPressed: undoLastBall),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            buildScoreCard(),
            SizedBox(height: 12),
            buildLogCard(),
            SizedBox(height: 12),
            if (!matchEnded) buildControls(),
          ],
        ),
      ),
    );
  }

  Widget buildScoreCard() => Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: Colors.blue.shade50,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Innings: $innings / 2', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Batting: $battingTeam', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
          SizedBox(height: 8),
          Text('Score: $runs / $wickets', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black87)),
          SizedBox(height: 8),
          Text('Overs: $oversDisplay', style: TextStyle(fontSize: 18)),
          if (innings == 2 && !matchEnded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Runs Needed: $runsNeeded    Balls Remaining: $ballsRemaining',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red.shade700)),
            ),
          if (matchEnded)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(resultText, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
            ),
        ],
      ),
    ),
  );

  Widget buildLogCard() => Expanded(
    child: Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ball-by-ball Log (latest first)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Divider(),
            Expanded(
              child: ballLogs.isEmpty
                  ? Center(child: Text('No balls yet.'))
                  : ListView.builder(
                reverse: false,
                itemCount: ballLogs.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(ballLogs[index], style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget buildControls() => Card(
    elevation: 5,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    color: Colors.blue.shade100,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text('Add Runs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
          SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(7, (index) => ElevatedButton(
              onPressed: () => addRuns(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                minimumSize: Size(48, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('$index', style: TextStyle(fontSize: 18)),
            )),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              customButton('Wide', addWide, Colors.orange.shade700),
              customButton('No Ball', addNoBall, Colors.orange.shade700),
              customButton('Wicket', addWicket, Colors.red.shade700),
              customButton('Run Out', addRunOut, Colors.red.shade400),
            ],
          ),
        ],
      ),
    ),
  );

  Widget customButton(String label, VoidCallback onPressed, Color color) => ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: Text(label, style: TextStyle(fontSize: 16)),
  );
}
