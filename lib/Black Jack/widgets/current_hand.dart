
import 'package:flutter/material.dart';
import 'package:roullet_app/Black%20Jack/models/playing_card.dart';
import 'package:roullet_app/Black%20Jack/widgets/card_visual.dart';

class CurrentHand extends StatefulWidget {
  final List<CardModel> cards;
  final bool hidden;

  const CurrentHand({super.key, required this.cards,required this.hidden});

  @override
  CurrentHandState createState() => CurrentHandState();
}

class CurrentHandState extends State<CurrentHand> {
  List cardList = [];

  @override
  Widget build(BuildContext context) {
    List<PlayingCard> cardList = [
      PlayingCard(cardModel: widget.cards[0], hidden: true),
      for (var i = 1; i < widget.cards.length; i++)
        PlayingCard(cardModel: widget.cards[i])
    ];
    if (widget.hidden == true) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: cardList,
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var card in widget.cards) PlayingCard(cardModel: card),
      ],
    );
  }

  add(PlayingCard card) {
    cardList.add(card);
  }
}
