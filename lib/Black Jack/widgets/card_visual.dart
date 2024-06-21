import 'package:flutter/material.dart';

import 'package:flip_card/flip_card.dart';
import 'package:flutter_null_safety_icons/flutter_icons.dart';
import 'package:roullet_app/Black%20Jack/models/playing_card.dart';
import 'package:roullet_app/Black%20Jack/screens/game_screen.dart';
import 'package:roullet_app/Helper_Constants/colors.dart';

class PlayingCard extends StatelessWidget {
  final CardModel cardModel;

  final bool hidden;

 const PlayingCard({super.key, required this.cardModel, this.hidden = false});


  @override
  Widget build(BuildContext context) {
    GameScreenState? state = context.findAncestorStateOfType<GameScreenState>();
    if (hidden) {
      return FlipCard(
        key: state?.cardKey,
        flipOnTouch: false,
        front: Container(
          decoration: BoxDecoration(
              border: Border.all(width: 0.8, color: colors.borderColorDark),
              // color: colors.borderColorLight,
              boxShadow: const [BoxShadow(offset: Offset(2.5, 2.5), blurRadius: 3)]),
          height: 60,
          width: 35,
          child: sideDown(),
        ),
        back: Container(
          decoration: BoxDecoration(
              border: Border.all(width: 1),
              color: Colors.white,
              boxShadow: const [BoxShadow(offset: Offset(2.5, 2.5), blurRadius: 3)]),
          height: 60,
          width: 35,
          child: sideUp(),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
            border: Border.all(width: 1),
            color: Colors.white,
            boxShadow: const [BoxShadow(offset: Offset(2.5, 2.5), blurRadius: 3,)]),
        height: 60,
        width: 35,
        child: sideUp(),
      );
    }
  }

  Widget cardSkeleton(Widget side) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(width: 1),
          color: Colors.white,
          boxShadow: const [BoxShadow(offset: Offset(2, 2), blurRadius: 3)]),
      height: 60,
      width: 35,
      child: hidden ? sideDown() : sideUp(),
    );
  }

  Widget sideUp() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_cardNumber(), style: TextStyle(color: _cardColor, fontSize: 16)),
        Icon(_cardSuit(), color: _cardColor),
      ],
    );
  }

  Widget sideDown() {
    return Container(
      // height: 60,
      //   width: 35,
        // color: colors.primary,
        decoration: BoxDecoration(
          gradient:LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
              colors: [
                colors.primary,
            colors.black54,
            colors.primary,
            //     colors.black54,
            // colors.primary,
            //     colors.black54,
            // colors.primary,
            // colors.black54,
          ])
        ),
        child: const Center(
          /*cards_playing_outline*/
          child: 
            Icon(MaterialCommunityIcons.cards_playing_outline,color: colors.borderColorLight,)
          // Text(
          //   "",
          //   style: TextStyle(color: Colors.white,fontSize: 10),
          //   textAlign: TextAlign.center,
          //
          // ),
        ));
  }

  Color get _cardColor {
    if (cardModel.cardColor == CardColor.red) {
      return Colors.red;
    } else {
      return Colors.black;
    }
  }

  String _cardNumber() {
    switch (cardModel.cardNumber) {
      case CardNumber.two:
        return '2';
      case CardNumber.three:
        return '3';
      case CardNumber.four:
        return '4';
      case CardNumber.five:
        return '5';
      case CardNumber.six:
        return '6';
      case CardNumber.seven:
        return '7';
      case CardNumber.eight:
        return '8';
      case CardNumber.nine:
        return '9';
      case CardNumber.ten:
        return '10';
      case CardNumber.jack:
        return 'J';
      case CardNumber.queen:
        return 'Q';
      case CardNumber.king:
        return 'K';
      case CardNumber.ace:
        return 'A';
      default:
        return '';
    }
  }

  IconData? _cardSuit() {
    switch (cardModel.cardSuit) {
      case CardSuit.clubs:
        return MaterialCommunityIcons.cards_club;
      case CardSuit.spades:
        return MaterialCommunityIcons.cards_spade;
      case CardSuit.hearts:
        return MaterialCommunityIcons.cards_heart;
      case CardSuit.diamonds:
        return MaterialCommunityIcons.cards_diamond;
      default:
        return null;
    }
  }
}
