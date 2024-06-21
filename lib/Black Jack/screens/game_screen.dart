import 'dart:math';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roullet_app/Black%20Jack/db/database_manager.dart';
import 'package:roullet_app/Black%20Jack/db/stats_dto.dart';
import 'package:roullet_app/Black%20Jack/models/player.dart';
import 'package:roullet_app/Black%20Jack/models/playing_card.dart';
import 'package:roullet_app/Black%20Jack/widgets/current_hand.dart';
import 'package:roullet_app/Helper_Constants/Images_path.dart';
import 'package:roullet_app/Helper_Constants/colors.dart';
import 'package:roullet_app/Helper_Constants/other_constants.dart';

class GameScreen extends StatefulWidget {
  static final routeName = '/';

  @override
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  List<CardModel> deck = [];

  Player player = Player();
  Player dealer = Player();

  CurrentHand? playerHand;
  CurrentHand? dealerHand;

  Random random = Random();

  String gameText = "";
  Widget? playerActions;

  final _statUpdate = StatsDTO();
  Map statData = {
    "roundsPlayed": 0,
    "playerWins": 0,
    "computerWins": 0,
  };

  final GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  @override
  void initState() {
    super.initState();
    loadData();
    createDeck(deck);
    dealInitialHand();
    playerActions = actionButtons(roundEnd: false);
  }

  @override
  Widget build(BuildContext context) {
    dealerHand = CurrentHand(cards: dealer.playerCards, hidden: true);
    playerHand = CurrentHand(
      cards: player.playerCards,
      hidden: false,
    );
    final winRate = statData["roundsPlayed"] > 0
        ? ((statData["playerWins"] / statData["roundsPlayed"]) * 100)
            .toStringAsFixed(2)
        : 0;
    return SafeArea(
      child: Scaffold(
        endDrawer: Drawer(
          child: ListView(
            children: [
              Container(
                height: 50,
                child: const DrawerHeader(
                  child: Text(
                    "Stats",
                    style: TextStyle(color: Colors.white),
                  ),
                  margin: EdgeInsets.all(0),
                ),
                color: const Color(0xFF225374),
              ),
              statsTile(text: "Rounds Played: ${statData["roundsPlayed"]}"),
              statsTile(text: "Player Wins: ${statData["playerWins"]}"),
              statsTile(text: "Computer Wins: ${statData["computerWins"]}"),
              statsTile(text: "Win Rate: $winRate%"),
              Container(
                color: Colors.red,
                child: ListTile(
                  visualDensity: VisualDensity.compact,
                  title: Text("Reset Statistics",
                      style: TextStyle(color: Colors.grey[100])),
                  onTap: resetStats,
                ),
              ),
            ],
          ),
        ),
        // backgroundColor: Colors.green[600],
        // appBar: AppBar(
        //   toolbarHeight: 40,
        //   backgroundColor: Colors.green[600],
        //   elevation: 0.0,
        // ),
        body: Container(
          height: Constants.screen.height,
          width: Constants.screen.width,
          decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
                colors.secondary,
                colors.primary,
                colors.secondary,
              ]),
              image: DecorationImage(
                  image: AssetImage(ImagesPath.backGroundImage),
                  fit: BoxFit.fill)),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const SizedBox(
                        height: 8,
                      ),
                      const Text(
                        'BLACKJACK',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: colors.borderColorLight,
                            fontSize: 30,
                            shadows: <Shadow>[
                              Shadow(
                                offset: Offset(2.0, 2.0),
                                blurRadius: 3.0,
                              ),
                            ]),
                      ),
                      gameText == ""
                          ? const SizedBox(
                              height: 10,
                            )
                          : Container(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                gameText,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 20),
                                textAlign: TextAlign.center,
                              ),
                            ),
                    ],
                  ),
                  // const SizedBox(height: 8,),
                  dealerHand!,
                  // const SizedBox(height: 16,),
                  playerHand!,
                  Text(playerTotal,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 20)),
                  playerActions!,
                ],
              ),
              Align(
                alignment: Alignment.topRight,
                child: Builder(builder: (context) {
                  return IconButton(
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                      icon: const Icon(
                        Icons.menu,
                        color: colors.borderColorLight,
                      ));
                }),
              )
            ],
          ),
        ),
      ),
    );
  }

  Column statsTile({String? text}) {
    return Column(
      children: [
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(top: 10, bottom: 10, left: 20),
          child: Text(text ?? ""),
        ),
        const Divider(
          height: 1,
        ),
      ],
    );
  }

  String get playerTotal {
    return player.handValue > 21
        ? "Total: ${player.handValue} BUST"
        : "Total: ${player.handValue}";
  }

  void resetDeck() {
    print("Resetting Deck... ");
    print("Cards left: ${deck.length}");
    if (deck.length < 26) {
      deck.clear();
      createDeck(deck);
    }
    playerActions = actionButtons(roundEnd: false);
    dealer.resetPlayer();
    player.resetPlayer();
    dealInitialHand();
    gameText = '';
    dealerHand = CurrentHand(cards: dealer.playerCards, hidden: true);
    playerHand = CurrentHand(
      cards: player.playerCards,
      hidden: false,
    );
    cardKey.currentState!.controller!.reset();

    determineBlackjack();
    setState(() {});
  }

  void createDeck(List deck) {
    CardSuit.values.forEach((suit) {
      CardNumber.values.forEach((number) {
        deck.add(CardModel(cardNumber: number, cardSuit: suit));
      });
    });
  }

  void dealInitialHand() {
    addCardsToHand(player);
    addCardsToHand(dealer);
    determineBlackjack();
  }

  void addCardsToHand(Player player) {
    for (var i = 0; i < player.cardsNeeded; i++) {
      int cardLocation = random.nextInt(deck.length);
      CardModel card = deck[cardLocation];
      player.playerCards.add(card);
      deck.removeAt(cardLocation);
    }
    playerHand = CurrentHand(
      cards: player.playerCards,
      hidden: false,
    );
    player.cardsNeeded = 0;
    if (player.hasBusted) {
      playerActions = actionButtons(roundEnd: true);
      _statUpdate.computerWins += 1;
      _statUpdate.roundsPlayed += 1;
      updateStats();
      setState(() {});
    }
  }

  Widget actionButtons({required bool roundEnd}) {
    if (!roundEnd) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          OutlinedButton(
            // shape: Border.all(width: 0.5),
            style: OutlinedButton.styleFrom(
                foregroundColor: colors.borderColorLight,
                backgroundColor: colors.borderColorLight.withOpacity(0.2),
                side: BorderSide(color: colors.borderColorLight),
                fixedSize: Size(120, 40)),
            child: const Text("Hit",
                style: TextStyle(
                  shadows: <Shadow>[
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 3.0,
                    )
                  ],
                )),
            onPressed: () {
              player.cardsNeeded += 1;
              addCardsToHand(player);
              setState(() {});
            },
            // elevation: 5,
            // color: Colors.blue[800],
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
                foregroundColor: colors.borderColorLight,
                backgroundColor: colors.borderColorLight.withOpacity(0.3),
                side: BorderSide(color: colors.borderColorLight),
                fixedSize: Size(120, 40)),

            // shape: Border.all(width: 0.5),
            child: const Text("Stand",
                style: TextStyle(
                  shadows: <Shadow>[
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 3.0,
                    )
                  ],
                )),
            onPressed: () => calculateWinner(player, dealer, blackjack: 0),
            // elevation: 5,
            // color: Colors.white,
          ),
          OutlinedButton(
            // shape: Border.all(width: 0.5),
            style: OutlinedButton.styleFrom(
                foregroundColor: colors.borderColorLight,
                backgroundColor: colors.borderColorLight.withOpacity(0.2),
                side: BorderSide(color: colors.borderColorLight),
                fixedSize: Size(120, 40)),
            child: const Text(
              "Reset Deck",
              style: TextStyle(shadows: <Shadow>[
                Shadow(
                  offset: Offset(2.0, 2.0),
                  blurRadius: 3.0,
                ),
              ]),
              // style: TextStyle(color: Colors.white),
            ),
            onPressed: resetDeck,
            // elevation: 5,
            // color: Colors.red,
          ),
        ],
      );
    } else {
      return  OutlinedButton(
        style: OutlinedButton.styleFrom(
            foregroundColor: colors.borderColorLight,
            backgroundColor: colors.borderColorLight.withOpacity(0.2),
            side: BorderSide(color: colors.borderColorLight),
            fixedSize: Size(120, 40)),
        // shape: Border.all(width: 0.5),
        child: const Text(
          "New Game",
          style: TextStyle(shadows: <Shadow>[
            Shadow(
              offset: Offset(2.0, 2.0),
              blurRadius: 3.0,
            ),
          ]),
          // style: TextStyle(color: Colors.purple),
        ),
        onPressed: resetDeck,
        // elevation: 5,
        // color: Colors.red,
      );
    }
  }

  void determineBlackjack() {
    if (player.handValue == 21 && dealer.handValue == 21) {
      calculateWinner(player, dealer, blackjack: 3);
    } else if (player.handValue == 21) {
      calculateWinner(player, dealer, blackjack: 1);
    } else if (dealer.handValue == 21) {
      calculateWinner(player, dealer, blackjack: 2);
    }
  }

  void calculateWinner(Player player, Player dealer, {int? blackjack}) {
    while (dealer.handValue < 17 && blackjack! < 1) {
      dealer.cardsNeeded += 1;
      addCardsToHand(dealer);
    }
    playerHand = CurrentHand(
      cards: player.playerCards,
      hidden: false,
    );
    cardKey.currentState!.controller!.forward();

    playerActions = actionButtons(roundEnd: true);

    if (player.hasBusted) {
      gameText = "The dealer wins.\nDealer's Total: ${dealer.handValue}";
      _statUpdate.computerWins += 1;
    } else if (!player.hasBusted && dealer.hasBusted) {
      gameText =
          "The dealer busted. You win!\nDealer's Total: ${dealer.handValue}";
      _statUpdate.playerWins += 1;
    } else if (dealer.handValue > player.handValue) {
      gameText = "The dealer wins\nDealer's Total: ${dealer.handValue}";
      _statUpdate.computerWins += 1;
    } else if (player.handValue > dealer.handValue) {
      gameText = "You win!\nDealer's Total: ${dealer.handValue}";
      _statUpdate.playerWins += 1;
    } else {
      gameText = "It's a tie!\nDealer's Total: ${dealer.handValue}";
    }

    _statUpdate.roundsPlayed += 1;

    updateStats();

    switch (blackjack) {
      case 1:
        gameText = "BLACKJACK. YOU WIN";
        break;
      case 2:
        gameText = "DEALER HAS BLACKJACK. YOU LOSE";
        break;
      case 3:
        gameText = "PUSH";
        break;
      default:
        break;
    }

    print("Current Stats: ${_statUpdate.toMap()}");

    setState(() {});
  }

  void updateStats() {
    final databaseManager = DatabaseManager.getInstance();
    databaseManager.updateData(dto: _statUpdate);
    statData = _statUpdate.toMap();
    print("UPDATING STATS: ${_statUpdate.toMap()}");
  }

  void resetStats() {
    final databaseManager = DatabaseManager.getInstance();
    final reset =
        StatsDTO(id: 1, playerWins: 0, computerWins: 0, roundsPlayed: 0);
    databaseManager.updateData(dto: reset);
    databaseManager.clearStats();
    databaseManager.addData(dto: reset);

    _statUpdate.computerWins = 0;
    _statUpdate.playerWins = 0;
    _statUpdate.roundsPlayed = 0;

    setState(() {
      statData = reset.toMap();
    });
  }

  void loadData() async {
    final databaseManager = DatabaseManager.getInstance();

    List<Map> stats = await databaseManager.getStats();

    print("Stats Length: ${stats.length}");
    print("Stats: $stats");

    if (stats.length == 0) {
      _statUpdate.id = 1;
      _statUpdate.playerWins = 0;
      _statUpdate.computerWins = 0;
      _statUpdate.roundsPlayed = 0;

      databaseManager.addData(dto: _statUpdate);
    } else {
      statData = stats[0];
      _statUpdate.id = stats[0]["id"];
      _statUpdate.computerWins = stats[0]["computerWins"];
      _statUpdate.playerWins = stats[0]["playerWins"];
      _statUpdate.roundsPlayed = stats[0]["roundsPlayed"];
      setState(() {});
    }
  }
}
