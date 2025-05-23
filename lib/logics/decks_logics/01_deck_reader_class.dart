//------------------------------------------------------------------------------

// STANDARD LIBRARIES
import 'dart:convert';
import 'package:flutter/services.dart';

// CUSTOM FILES
import 'package:loverquest/logics/decks_logics/02_deck_summary_class.dart';
import 'package:loverquest/logics/decks_logics/03_quest_class.dart';

// HIVE
import 'package:hive_flutter/hive_flutter.dart';

// SETTING THE GENERATION OF G.DART FILE
part '01_deck_reader_class.g.dart';

// SETTING THE HIVE STORAGE ID
@HiveType(typeId: 4)

//------------------------------------------------------------------------------

// DEFAULT DECK MANAGER CLASS
class DeckReader {

  //------------------------------------------------------------------------------

  // QUEST MANAGER ATTRIBUTES
  @HiveField(0)
  DeckSummary summary;

  @HiveField(1)
  List<Quest> quests;

  @HiveField(2)
  final String deck_file_path;

  // DEFAULT CLASS CONSTRUCTOR
  DeckReader(this.deck_file_path)
      : summary = DeckSummary(
    name: "Unknown title",
    description: "No description, sorry",
    couple_type: "lesbian",
    play_presence: false,
    language: "en",
    total_quests: 0,
    required_tools: [],
    tags: [],
  ),
        quests = [];

  // EMPTY CLASS CONSTRUCTOR
  DeckReader.empty()
      : summary = DeckSummary(
    name: "Unknown title",
    description: "No description, sorry",
    couple_type: "lesbian",
    play_presence: false,
    language: "en",
    total_quests: 0,
    required_tools: [],
    tags: [],
  ),
        quests = [],
        deck_file_path = "unknown_path";

  //------------------------------------------------------------------------------

  // LOADING JSON FROM ASSETS AND CONVERTING IT IN OBJECTS METHOD
  Future<void> load_deck() async {

    try {
      
      // DEFINING THE JSON STRING VAR
      String json_string;

      // CHECKING IF THE FILE IS FROM THE CUSTOM FOLDER OR FROM THE ASSETS
      if (deck_file_path.contains('assets/')) {

        // THE FILE IS FROM THE ASSETS

        // LOADING JSON AS STRING WITH ROOT BUNDLE
        json_string = await rootBundle.loadString(deck_file_path);

        // DECODING JSON FILE
        final Map<String, dynamic> jsonData = json.decode(json_string);

        // ACQUIRING DECKS SUMMARY
        summary = DeckSummary.fromJson(jsonData['summary']);

        // ACQUIRING DECKS QUESTS
        quests = (jsonData['quests'] as List).map((q) => Quest.fromJson(q)).toList();

      } else {

        // THE FILE IS FROM THE CUSTOM DECKS

        // OPENING THE HIVE BOX
        var box = await Hive.openBox('customDecks');
        Map? data = box.get(deck_file_path);

        // CHECKING THAT THE DATA EXIST
        if (data != null) {

          // LOADING THE DECK SUMMARY
          summary = data['summary'] as DeckSummary;

          // LOADING THE QUESTS LIST
          quests = List<Quest>.from(data['quests']);

        } else {

          // LOADING THE DEFAULT DECK SUMMARY VALUES
          summary = DeckSummary(
            name: "Error",
            description: "This deck does not exist",
            couple_type: "hetero",
            play_presence: false,
            language: "en",
            total_quests: 0,
            required_tools: [],
            tags: [],
          );

          // LOADING THE DEFAULT QUESTS LIST
          quests = [];

        }

      }

    } catch (e) {
      quests = [];
    }

  }

  //------------------------------------------------------------------------------

  // FROM OBJECT TO JSON CONVERSION METHOD
  Map<String, dynamic> toJson() {
    return {
      'summary': summary.toJson(),
      'quests': quests.map((q) => q.toJson()).toList(),
      'deck_file_path': deck_file_path,
    };
  }

  //------------------------------------------------------------------------------

  // FROM JSON TO OBJECT CONVERSION
  factory DeckReader.fromJson(Map<String, dynamic> json) {

    DeckReader deck = DeckReader(json['deck_file_path'] ?? 'unknown_path');
    deck.summary = DeckSummary.fromJson(json['summary']);
    deck.quests = (json['quests'] as List).map((q) => Quest.fromJson(q)).toList();

    return deck;
  }

  //------------------------------------------------------------------------------


}

//------------------------------------------------------------------------------