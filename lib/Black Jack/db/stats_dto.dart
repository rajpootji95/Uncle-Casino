class StatsDTO {
  int? id;
  int playerWins ;
  int computerWins ;
  int roundsPlayed ;

  StatsDTO({this.id, this.playerWins = 0 , this.computerWins = 0, this.roundsPlayed = 0});

  get getEntries {
    return 'Stats: $roundsPlayed, $playerWins, $computerWins';
  }

    Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playerWins': playerWins,
      'computerWins': computerWins,
      'roundsPlayed': roundsPlayed,
    };
  }
}