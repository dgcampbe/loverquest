//------------------------------------------------------------------------------

// STANDARD LIBRARIES
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loverquest/l10n/app_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';


// CUSTOM FILES
import 'package:loverquest/logics/decks_logics/01_deck_reader_class.dart';
import 'package:loverquest/logics/decks_logics/04_deck_management_class.dart';


import 'package:loverquest/logics/decks_logics/06_reed_deck_list_getter.dart';

import 'package:loverquest/logics/ui_logics/01_tags_ui_class.dart';
import 'package:loverquest/logics/decks_logics/deck_filters.dart';
import 'package:loverquest/pages/decks_pages/dialogs/01_deck_filters_ui_page.dart';
import 'package:loverquest/pages/decks_pages/02_stock_deck_inspector_page.dart';
import 'package:loverquest/pages/decks_pages/03_deck_editor_main_page.dart';
import 'package:loverquest/pages/decks_pages/dialogs/02_delete_deck_dialog.dart';
import 'package:loverquest/pages/decks_pages/04_edit_deck_summary_page.dart';

// HIVE
import 'package:hive_flutter/hive_flutter.dart';


//------------------------------------------------------------------------------



// DECK MANAGEMENT PAGE DEFINITION
class DeckManagementPage extends StatefulWidget {

  // CLASS PARAMETERS
  final bool load_default_decks;
  final DeckReader? deck_to_edit;

  // CLASS CONSTRUCTOR
  const DeckManagementPage({required this.load_default_decks, this. deck_to_edit, super.key});

  @override
  State<DeckManagementPage> createState() => _DeckManagementPageState();

}



// DECK MANAGEMENT PAGE CONTENT
class _DeckManagementPageState extends State<DeckManagementPage> {

  //------------------------------------------------------------------------------

  // DEFINING THE APP PREFERENCE VAR
  late SharedPreferences prefs;

  //------------------------------------------------------------------------------

  // DEFINING LOADED DECKS LIST AND FILTERED DECKS LIST
  List<String> decks_path_list = [];
  List<DeckReader> loaded_decks_list = [];
  List<DeckReader> filtered_decks_list = [];

  // DEFINING IS LOADING VARIABLE
  bool is_loading = true;

  // DEFINING THE IS INITIALIZED VARIABLE
  bool is_initialized = false;

  //------------------------------------------------------------------------------

  // DEFINING THE FILTERS VAR
  String selected_option_couple_type = 'all';
  String selected_option_game_type = 'both';

  //------------------------------------------------------------------------------

  // CLASS INITIAL STATE
  @override
  void initState() {
    super.initState();

    // WAITING FOR THE END OF THE FIRST FRAME
    WidgetsBinding.instance.addPostFrameCallback((_) {

      Future.microtask(() async {

        // LOADING THE APP PREFERENCE
        prefs = await SharedPreferences.getInstance();

        // CHECKING IF IS NECESSARY TO SHOW THE SPLASH SCREEN
        await check_warning_screen();

      });



      // CHECKING THAT THE GIVEN DECK IS NOT NULL
      if (widget.deck_to_edit != null) {

        // OPENING THE EDIT MAIN PAGE
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeckEditMainPage(selected_deck: widget.deck_to_edit!),
          ),
        );

      }

    });

  }

  // CLASS CODE EXECUTED AFTER EVERY RELOADING
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();



    // LAUNCH THE FUNCTION TO LOAD ALL DEFAULT DECKS
    if (widget.load_default_decks == true) {

      // CHECKING IF THE LIST HAS BEEN ALREADY LOADED IN ORDER TO AVOID MULTIPLE LOADING
      if (!is_initialized) {

        is_initialized = true;
        load_all_default_decks();

      }

    } else {

      // CHECKING IF THE LIST HAS BEEN ALREADY LOADED IN ORDER TO AVOID MULTIPLE LOADING
      if (!is_initialized) {

        is_initialized = true;
        load_all_custom_decks();

      }



    }

  }

  //------------------------------------------------------------------------------

  // CHECKING IF IS THE FIRST TIME THAT THE APP IS OPENED IN ORDER TO SHOW THE SPLASH SCREEN
  Future<void> check_warning_screen () async {

    // GETTING THE SPLASH SCREEN PREFERENCE, IF THERE ARE NOT SETTING IT TO ZERO
    bool show_warning_screen = prefs.getBool('show_warning_screen') ?? true;

    // CHECKING IF IS NECESSARY TO SHOW THE SPLASH SCREEN
    if (show_warning_screen && kIsWeb && !widget.load_default_decks) {

      // SHOWING THE SPLASH SCREEN
      show_warning_screen_dialog(context);

      // SETTING THE SPLASH SCREEN AS SHOWED
      await prefs.setBool('show_warning_screen', false);

    }

  }

  // APP SPLASH SCREEN DIALOG
  void show_warning_screen_dialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {

        //------------------------------------------------------------------------------

        // DIALOG
        return AlertDialog(

          // DIALOG TITLE
          title: Text(

            // TEXT
            AppLocalizations.of(context)!.deck_management_page_warning_dialog_title,

            // ALIGNMENT
            textAlign: TextAlign.center,

            // STYLE
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),

          ),

          // DIALOG CONTENT
          content: Container(

            // SETTING THE WIDTH LIMIT
            constraints: BoxConstraints(maxWidth: 500),

            // CONTAINER CONTENT
            child: SingleChildScrollView(

              child: Text(

                // TEXT
                AppLocalizations.of(context)!.deck_management_page_warning_dialog_content,

                // ALIGNMENT
                textAlign: TextAlign.center,

                // STYLE
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.normal,
                ),

              ),

            ),

          ),

          // DIALOG BUTTONS
          actions: [

            // BUTTON ROW
            Row(

              // ALIGN
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,

              // ROW CONTENT
              children: [

                // EXIT BUTTON
                TextButton(

                  // STYLE
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.onPrimary),
                    backgroundColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.primary),
                    padding: WidgetStateProperty.all(
                        EdgeInsets.symmetric(horizontal: 15, vertical: 10)),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),

                  // FUNCTION
                  onPressed: () => Navigator.of(context).pop(),

                  // BUTTON CONTENT
                  child: Text(

                    // TEXT
                    AppLocalizations.of(context)!.deck_management_page_warning_dialog_ok_button,

                  ),

                ),



              ],

            ),

          ],


        );

      },

    );

  }

  //------------------------------------------------------------------------------

  // INITIAL STATE FUNCTION TO LOAD ALL DEFAULTS DECKS
  Future<void> load_all_default_decks() async {

    //------------------------------------------------------------------------------

    // GETTING THE DEFAULT REED DECK LIST
    List<DeckReader> default_reed_deck_list = await get_default_reed_decks(context);

    //------------------------------------------------------------------------------

    // UPDATING THE WIDGET STATUS WITH THE LOADED DATA
    setState(() {
      loaded_decks_list = default_reed_deck_list;
      filtered_decks_list = loaded_decks_list;
      is_loading = false;
    });
  }

  //------------------------------------------------------------------------------

  // INITIAL STATE FUNCTION TO LOAD ALL CUSTOM DECKS FROM HIVE
  Future<void> load_all_custom_decks() async {

    //------------------------------------------------------------------------------

    // OPENING THE CUSTOM DECK HIVE BOX
    final box = await Hive.openBox('customDecks');

    // GETTING ALL THE DECKS KEYS
    List<String> decks_keys = box.keys.cast<String>().toList();

    //------------------------------------------------------------------------------

    // INITIALIZING THE TEMP CUSTOM DECKS LIST
    List<DeckReader> temp_list = [];

   // LOADING AND READING ALL THE CUSTOM DECKS 
    for (String deck_key in decks_keys) {
      
      // LOADING THE DECK
      DeckReader deckManager = DeckReader(deck_key);
      
      // READING THE DECK
      await deckManager.load_deck();
      
      // ADDING THE DECK TO THE TEMP LIST
      temp_list.add(deckManager);
    }

    //------------------------------------------------------------------------------

    // UPDATING THE WIDGET STATUS
    setState(() {
      loaded_decks_list = temp_list;
      filtered_decks_list = loaded_decks_list;
      is_loading = false;
    });
  }

  //------------------------------------------------------------------------------

  // FUNCTION TO APPLY FILTERS SELECTED IN THE FILTERS DIALOG
  void apply_deck_filters() {

    // CHANGING PAGE STATE
    setState(() {

      // GETTING THE LIST OF ALL DECKS
      List<DeckReader> temp_filtered_list = List.from(loaded_decks_list);

      // DEFINING THE PLAY DISTANCE VAR
      bool play_presence = true;

      // CHECKING IF THE COUPLE FILTER HAS BEEN SET
      if (selected_option_couple_type != 'all') {

        // FILTERING THE LIST FOR COUPLE TYPE
        temp_filtered_list = filter_decks_for_couple_type(temp_filtered_list, selected_option_couple_type);

      }

      // CHECKING IF THE GAME TYPE FILTER HAS BEEN SET
      if (selected_option_game_type != 'both') {

        // CHECKING IF WHICH IS THE SELECTED FILTER
        if (selected_option_game_type != "distance") {

          // SETTING THE FILTER AS PRESENCE ONLY
          play_presence = true;

          // SETTING THE FILTER AS LOCAL ONLY
        } else {play_presence = false;}

        // GETTING THE FILTERED LIST
        temp_filtered_list = filter_decks_for_presence_distance(temp_filtered_list, play_presence);

      }

      // SETTING THE FILTERED DECK LIST
      filtered_decks_list = temp_filtered_list;

    });
  }

  //------------------------------------------------------------------------------

  // FUNCTION TO SHOW THE FILTER DIALOG
  void show_deck_filter_dialog() {
    showDialog(
      context: context,
      builder: (context) => DeckFilterDialog(
        on_filter_selected: (String newCoupleType, String newGameType) {
          setState(() {

            // SETTING THE CHOOSE OPTION
            selected_option_couple_type = newCoupleType;

            // SETTING THE CHOOSE OPTION
            selected_option_game_type = newGameType;

            // APPLYING THE FILTERS TO THE VIEW
            apply_deck_filters();

          });
        },
      ),
    );
  }

  //------------------------------------------------------------------------------

  // FUNCTION TO SHOW THE DELETE CONFIRMATION DIALOG
  void show_deck_delete_dialog(String deck_file_path, String deck_name) {
    showDialog(
      context: context,
      builder: (context) => DeckDeleteDialog(
        deck_file_path: deck_file_path,
        deck_name: deck_name,
      ),
    ).then((result) async {

      // RELOADING THE INTERFACE
      await load_all_custom_decks();

    });

  }

  //------------------------------------------------------------------------------

  // PAGE CONTENT
  @override
  Widget build(BuildContext context) {

    //------------------------------------------------------------------------------

    // IF THE APP IS STILL LOADING THE DECKS, SHOWS A LOADING SCREEN
    if (is_loading) {

      // DEFINING LOADING SCREEN
      return Scaffold(

        // PAGE CONTENT
        body: SafeArea(

          // SAFE AREA CONTENT
            child: Center(

              // LOADING CIRCLE
              child: CircularProgressIndicator(

                // WHEEL COLOR
                color: Theme.of(context).colorScheme.onPrimary,

                // WHEEL WIDTH
                strokeWidth: 4,

              ),

            )

        ),

      );

    }

    //------------------------------------------------------------------------------

    // CONTENT ENTRY POINT
    return Scaffold(

      // APP BAR CONTENT
      appBar: AppBar(

        // DEFINING THE ACTION BUTTONS
        actions: [

          // NEW DECK ICON BUTTON
          !widget.load_default_decks ?IconButton(
            icon: Icon(Icons.add),
            onPressed: () {

              // PAGE LINKER
              Navigator.push(
                  context,
                  MaterialPageRoute(

                    // OPEN NEW PAGE
                    builder: (context) => DeckSummaryEditPage(),
                  ),
              ).then((result) async {

                // UPDATING THE PAGE LIST
                await load_all_custom_decks();

                setState(() {

                });

              });


            },
          ): SizedBox.shrink(),

          // FILTER ICON BUTTON
          IconButton(
            icon: Icon(Icons.filter_alt_rounded),
            onPressed: () => show_deck_filter_dialog(),
          ),

          // IMPORT DECK ICON BUTTON
          !widget.load_default_decks ?IconButton(
            icon: Icon(Icons.download_rounded),
            onPressed: () async {

              // IMPORTING THE CUSTOM DECK
              bool deck_correct_imported = await DeckManagement.import_json_file_to_hive();

              // CHECKING IF THE INTERFACE IS STILL MOUNTED
              if (!mounted) return;

              // CHECKING IF THE CUSTOM DECK WAS CORRECTLY IMPORTED
              if (!deck_correct_imported) {

                // SHOWING ERROR POPUP
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(

                    // POP-UP CONTENT
                    content: Row(

                      // ALIGNMENT
                      mainAxisAlignment: MainAxisAlignment.center,

                      // SIZE
                      mainAxisSize: MainAxisSize.max,

                      // ROW CONTENT
                      children: [

                        // ERROR TEXT
                        Flexible(

                          child: Text(
                            // TEXT
                            // ignore: use_build_context_synchronously
                            AppLocalizations.of(context)!.deck_management_page_import_error_text,

                            // TEXT STYLE
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: Color.fromRGBO(226, 226, 226, 1.0),
                            ),

                            // TEXT GO TO NEXT ROW
                            softWrap: true,

                            // MAX NUMBERS OF TEXT LINE
                            maxLines: 3,

                            // WHAT SHOW IF LONGER
                            overflow: TextOverflow.ellipsis,

                          ),

                        )

                      ],

                    ),

                    // POP-UP DURATION
                    duration: Duration(seconds: 4),

                    // POP-UP BACKGROUND COLOR
                    backgroundColor: Color.fromRGBO(73, 32, 32, 1.0),

                  ),
                );

              }

              // RELOADING THE PAGE
              await load_all_custom_decks();

            },
          ): SizedBox.shrink(),

        ],

      ),



      // SCAFFOLD CONTENT
      body: SafeArea(

        // SAFE AREA CONTENT
        child: Align(

          // ALIGNMENT
          alignment: Alignment.center,

          // ALIGN CONTENT
          child: Container(

            // SETTING THE WIDTH LIMIT
            constraints: BoxConstraints(maxWidth: 600),

            // PAGE PADDING
            padding: EdgeInsets.all(10),

            // PAGE ALIGNMENT
            alignment: Alignment.topCenter,

            // TEXT TO DISPLAY IF THERE ARE NO DECKS
            child: filtered_decks_list.isEmpty ? Center(

              child: Text(

                AppLocalizations.of(context)!.deck_management_page_no_decks_text,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),

            )

            // DYNAMIC PART OF THE PAGE
            : CustomScrollView (

              // PAGE CONTENT
              slivers: [

                //------------------------------------------------------------------------------

                // STATIC PART OF THE PAGE
                SliverToBoxAdapter(

                  // CONTAINER CONTENT
                  child: Column(

                    // SIZE
                    mainAxisSize: MainAxisSize.min,

                    // COLUMN CONTENT
                    children: [

                      //------------------------------------------------------------------------------

                      // PAGE TITLE CONTAINER
                      FractionallySizedBox(

                        // DYNAMIC WIDTH
                        widthFactor: 0.8,

                        // TITLE
                        child: Text(
                          // TEXT
                          widget.load_default_decks ?AppLocalizations.of(context)!.deck_management_page_default_deck_list: AppLocalizations.of(context)!.deck_management_page_custom_deck_list,

                          // TEXT ALIGNMENT
                          textAlign: TextAlign.center,

                          // TEXT STYLE
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,

                          ),
                        ),

                      ),

                      //------------------------------------------------------------------------------

                      // SPACER
                      const SizedBox(height: 30),

                      //------------------------------------------------------------------------------

                    ],

                  ),

                ),

                //------------------------------------------------------------------------------

                 SliverList(

                  // DYNAMIC PART OF THE WIDGET
                  delegate: SliverChildBuilderDelegate(

                        (context, index) {

                      //------------------------------------------------------------------------------

                      String deck_file_path = filtered_decks_list[index].deck_file_path;
                      String deck_name = filtered_decks_list[index].summary.name;
                      int deck_quest_number = filtered_decks_list[index].summary.total_quests;

                      //------------------------------------------------------------------------------

                      // GETTING DECK TAG INFO
                      LanguageInfo language_info_object = get_language_info(context, filtered_decks_list[index].summary.language);
                      CoupleTypeInfo couple_type_info_object = get_couple_type_info(context, filtered_decks_list[index].summary.couple_type);
                      GameTypeInfo game_type_info_object = get_game_type_type_info(context, filtered_decks_list[index].summary.play_presence);
                      ToolsInfo tools_info_object = get_tools_info(context, filtered_decks_list[index].summary.required_tools);

                      OralSexTagInfo oral_sex_tag_object = get_oral_tag_info(context, filtered_decks_list[index].summary.tags);
                      AnalSexTagInfo anal_sex_tag_object = get_anal_tag_info(context, filtered_decks_list[index].summary.tags);
                      VaginalSexTagInfo vaginal_sex_tag_object = get_vaginal_tag_info(context, filtered_decks_list[index].summary.tags);
                      BondageTagInfo bondage_tag_object = get_bondage_tag_info(context, filtered_decks_list[index].summary.tags);
                      BdsmTagInfo bdsm_tag_object = get_bdsm_tag_info(context, filtered_decks_list[index].summary.tags);

                      ChatTagInfo chat_tag_object = get_chat_tag_info(context, filtered_decks_list[index].summary.tags);
                      VideoCallTagInfo video_call_tag_object = get_video_call_tag_info(context, filtered_decks_list[index].summary.tags);

                      //------------------------------------------------------------------------------

                      // DYNAMIC LIST CONTENT
                      return Align(

                        // ALIGNMENT
                        alignment: Alignment.center,

                        // ALIGNMENT CONTENT
                        child: Column(

                          // COLUMN CONTENT
                          children: [

                            // SETTING GESTURE DETECTOR IN ORDER TO GET LONG PRESS ACTION
                            GestureDetector(

                              //------------------------------------------------------------------------------

                              // LONG PRESS CONDITION SETUP
                              onLongPressStart: (details) {
                                showMenu(
                                  context: context,

                                  // MENU POSITION
                                  position: RelativeRect.fromLTRB(
                                      details.globalPosition.dx,
                                      details.globalPosition.dy,
                                      details.globalPosition.dx + 1,
                                      details.globalPosition.dy + 1
                                  ),

                                  // MENU CONTENT
                                  items: [

                                    if (!widget.load_default_decks)

                                      // DELETE ENTRY
                                      PopupMenuItem(

                                        // ENTRY VALUE
                                        value: 'delete',

                                        // ENTRY CONTENT
                                        child: Row(

                                          // ROW CONTENT
                                          children: [

                                            // ENTRY ICON
                                            Icon(

                                              // ICON
                                              Icons.delete,

                                              // ICON SIZE
                                              size: 18,

                                            ),

                                            // SPACER
                                            SizedBox(width: 5),

                                            // ENTRY TEXT
                                            Expanded(child: Text(AppLocalizations.of(context)!.deck_management_press_menu_delete)),

                                          ],

                                        ),

                                      ),

                                    // EXPORT ENTRY
                                    PopupMenuItem(

                                      // ENTRY VALUE
                                      value: 'export',

                                      // ENTRY CONTENT
                                      child: Row(

                                        // ROW CONTENT
                                        children: [

                                          // ENTRY ICON
                                          Icon(

                                            // ICON
                                            Icons.share,

                                            // ICON SIZE
                                            size: 18,

                                          ),

                                          // SPACER
                                          SizedBox(width: 5),

                                          // ENTRY TEXT
                                          Expanded(child: Text(AppLocalizations.of(context)!.deck_management_press_menu_export)),

                                        ],

                                      ),

                                    ),

                                    if (!widget.load_default_decks)

                                      // DUPLICATE ENTRY
                                      PopupMenuItem(

                                        // ENTRY VALUE
                                        value: 'duplicate',

                                        // ENTRY CONTENT
                                        child: Row(

                                          // ROW CONTENT
                                          children: [

                                            // ENTRY ICON
                                            Icon(

                                              // ICON
                                              Icons.copy,

                                              // ICON SIZE
                                              size: 18,

                                            ),

                                            // SPACER
                                            SizedBox(width: 5),

                                            // ENTRY TEXT
                                            Expanded(child: Text(AppLocalizations.of(context)!.deck_management_press_menu_duplicate)),

                                          ],

                                        ),

                                      ),

                                    if (widget.load_default_decks)

                                      // EDIT ENTRY
                                      PopupMenuItem(

                                        // ENTRY VALUE
                                        value: 'edit',

                                        // ENTRY CONTENT
                                        child: Row(

                                          // ROW CONTENT
                                          children: [

                                            // ENTRY ICON
                                            Icon(

                                              // ICON
                                              Icons.edit,

                                              // ICON SIZE
                                              size: 18,

                                            ),

                                            // SPACER
                                            SizedBox(width: 5),

                                            // ENTRY TEXT
                                            Expanded(child: Text(AppLocalizations.of(context)!.deck_management_press_menu_edit)),

                                          ],

                                        ),

                                      ),

                                  ],

                                  // MENU CONDITION ON ANY BUTTON PRESSED
                                ).then((value) async {

                                  // CHECKING WHICH OPTION WAS CHOOSE
                                  if (value == "export") {

                                    if (widget.load_default_decks) {

                                      // EXPORTING THE DECK
                                      await DeckManagement.export_json_file(deck_file_path, deck_name, isAsset: true);

                                    } else {

                                      // EXPORTING THE DECK
                                      await DeckManagement.export_json_file_from_hive(deck_name);

                                    }

                                  } else if (value == "delete") {

                                    // SHOWING THE DELETE DIALOG
                                    show_deck_delete_dialog(deck_file_path, deck_name);

                                  } else if (value == "duplicate") {

                                    // SAVING THE DECK
                                    await DeckManagement.save_deck(

                                      deck_name: "${filtered_decks_list[index].summary.name}_2",
                                      deck_description: filtered_decks_list[index].summary.description,
                                      deck_language: filtered_decks_list[index].summary.language,
                                      couple_type: filtered_decks_list[index].summary.couple_type,
                                      play_presence: filtered_decks_list[index].summary.play_presence,
                                      deck_tags: filtered_decks_list[index].summary.tags,
                                      selected_deck: filtered_decks_list[index],

                                    );

                                    // UPDATING THE PAGE LIST
                                    await load_all_custom_decks();

                                    setState(() {

                                    });

                                  } else if (value == "edit") {

                                    // SAVING THE DECK
                                   String new_duplicated_deck_file_path = await DeckManagement.save_deck(

                                        deck_name: "${filtered_decks_list[index].summary.name}_2",
                                        deck_description: filtered_decks_list[index].summary.description,
                                        deck_language: filtered_decks_list[index].summary.language,
                                        couple_type: filtered_decks_list[index].summary.couple_type,
                                        play_presence: filtered_decks_list[index].summary.play_presence,
                                        deck_tags: filtered_decks_list[index].summary.tags,
                                        selected_deck: filtered_decks_list[index],

                                    );

                                   // INITIALIZING THE DUPLICATED DECK
                                   DeckReader new_duplicated_deck = DeckReader(new_duplicated_deck_file_path);

                                   // LOADING THE DUPLICATED DECK
                                   await new_duplicated_deck.load_deck();

                                   // CHECKING IF THE INTERFACE IS STILL MOUNTED
                                   if (!mounted) return;

                                   // GOING TO THE NEXT PAGE
                                   Navigator.pushReplacement(
                                     // ignore: use_build_context_synchronously
                                     context,
                                     MaterialPageRoute(
                                       builder: (context) => DeckManagementPage(load_default_decks: false, deck_to_edit: new_duplicated_deck,),
                                     ),
                                   );

                                  }


                                });

                              },

                              //------------------------------------------------------------------------------

                              // DECK BUTTON
                              child:  ElevatedButton(

                                //------------------------------------------------------------------------------

                                // BUTTON STYLE PARAMETERS
                                style: ButtonStyle(

                                  // NORMAL TEXT COLOR
                                  foregroundColor: WidgetStateProperty.all(
                                      Theme.of(context).colorScheme.onPrimary
                                  ),

                                  // NORMAL BACKGROUND COLOR
                                  backgroundColor: WidgetStateProperty.all(
                                    Theme.of(context).colorScheme.primary,
                                  ),

                                  // CORNERS RADIUS
                                  shape:
                                  WidgetStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),

                                  // PADDING
                                  padding: WidgetStateProperty.all<EdgeInsets>(
                                    EdgeInsets.symmetric(horizontal: 25, vertical: 25),
                                  ),

                                ),

                                //------------------------------------------------------------------------------

                                // ON PRESSED CALL
                                onPressed: () {

                                  // IF WAS OPENED THE DEFAULT DECKS VIEW
                                  if (widget.load_default_decks) {

                                    // PAGE LINKER
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(

                                        // OPEN NEW PAGE
                                        builder: (context) => DeckInfoPage(

                                          selected_deck: filtered_decks_list[index],

                                        ),

                                      ),

                                    );

                                  } else {
                                    // PAGE LINKER
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(

                                        // OPEN NEW PAGE
                                        builder: (context) =>
                                            DeckEditMainPage(

                                              selected_deck: filtered_decks_list[index],

                                            ),

                                      ),

                                    ).then((reload) async {

                                      // UPDATING THE PAGE LIST
                                      await load_all_custom_decks();

                                      setState(() {

                                      });

                                    });
                                  }
                                },

                                //------------------------------------------------------------------------------

                                // BUTT0N CONTENT
                                child: Row(

                                  // ROW CONTENT
                                  children: [

                                    //------------------------------------------------------------------------------

                                    // COLUMN
                                    Expanded(
                                      child: Column(

                                        // COLUMN ALIGNMENT
                                        crossAxisAlignment:CrossAxisAlignment.start,

                                        children: [

                                          //------------------------------------------------------------------------------

                                          // CARD TEXT
                                          Text(
                                            // TEXT
                                            deck_name,

                                            // TEXT STYLE
                                            style: TextStyle(
                                              fontSize: 18.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),

                                          //------------------------------------------------------------------------------

                                          // SPACER
                                          const SizedBox(height: 15),

                                          //------------------------------------------------------------------------------

                                          // TAGS BOX
                                          Wrap(

                                            // ELEMENTS HORIZONTAL SPACING
                                            spacing: 5,

                                            // ELEMENTS VERTICAL SPACING
                                            runSpacing: 7,

                                            children: [

                                              //------------------------------------------------------------------------------

                                              // LANGUAGE TAG
                                              Container(

                                                // PADDING
                                                padding: EdgeInsets.all(7),

                                                //CONTAINER STYLE
                                                decoration: BoxDecoration(

                                                  // BACKGROUND COLOR
                                                  color: language_info_object.background_color,

                                                  // BORDER RADIUS
                                                  borderRadius: BorderRadius.circular(16),

                                                  // BORDER STYLE
                                                  border: Border.all(
                                                    color: language_info_object.background_color,
                                                    width: 1,
                                                  ),

                                                ),

                                                // CONTAINER CONTENT
                                                child: Text(

                                                  // TEXT
                                                  language_info_object.label,

                                                  // TEXT STYLE
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),

                                                ),

                                              ),

                                              //------------------------------------------------------------------------------

                                              // COUPLE TYPE TAG
                                              Container(

                                                // PADDING
                                                padding: EdgeInsets.all(7),

                                                //CONTAINER STYLE
                                                decoration: BoxDecoration(

                                                  // BACKGROUND COLOR
                                                  color: couple_type_info_object.background_color,

                                                  // BORDER RADIUS
                                                  borderRadius: BorderRadius.circular(16),

                                                  // BORDER STYLE
                                                  border: Border.all(
                                                    color: couple_type_info_object.background_color,
                                                    width: 1,
                                                  ),

                                                ),

                                                // CONTAINER CONTENT
                                                child: Text(

                                                  // TEXT
                                                  couple_type_info_object.label,

                                                  // TEXT STYLE
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),

                                                ),

                                              ),

                                              //------------------------------------------------------------------------------

                                              // GAME TYPE TAG
                                              Container(

                                                // PADDING
                                                padding: EdgeInsets.all(7),

                                                //CONTAINER STYLE
                                                decoration: BoxDecoration(

                                                  // BACKGROUND COLOR
                                                  color: game_type_info_object.background_color,

                                                  // BORDER RADIUS
                                                  borderRadius: BorderRadius.circular(16),

                                                  // BORDER STYLE
                                                  border: Border.all(
                                                    color: game_type_info_object.background_color,
                                                    width: 1,
                                                  ),

                                                ),

                                                // CONTAINER CONTENT
                                                child: Text(

                                                  // TEXT
                                                  game_type_info_object.label,

                                                  // TEXT STYLE
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),

                                                ),

                                              ),

                                              //------------------------------------------------------------------------------

                                              // TOOLS TAG
                                              Container(

                                                // PADDING
                                                padding: EdgeInsets.all(7),

                                                //CONTAINER STYLE
                                                decoration: BoxDecoration(

                                                  // BACKGROUND COLOR
                                                  color: tools_info_object.background_color,

                                                  // BORDER RADIUS
                                                  borderRadius: BorderRadius.circular(16),

                                                  // BORDER STYLE
                                                  border: Border.all(
                                                    color: tools_info_object.background_color,
                                                    width: 1,
                                                  ),

                                                ),

                                                // CONTAINER CONTENT
                                                child: Text(

                                                  // TEXT
                                                  tools_info_object.label,

                                                  // TEXT STYLE
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),

                                                ),

                                              ),

                                              //------------------------------------------------------------------------------

                                              // QUEST NUMBER TAG
                                              Container(

                                                // PADDING
                                                padding: EdgeInsets.all(7),

                                                //CONTAINER STYLE
                                                decoration: BoxDecoration(

                                                  // BACKGROUND COLOR
                                                  color: Color(0xff376255),

                                                  // BORDER RADIUS
                                                  borderRadius: BorderRadius.circular(16),

                                                  // BORDER STYLE
                                                  border: Border.all(
                                                    color: Color(0xff376255),
                                                    width: 1,
                                                  ),

                                                ),

                                                // CONTAINER CONTENT
                                                child: Text(

                                                  // TEXT
                                                  '$deck_quest_number quest',

                                                  // TEXT STYLE
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),

                                                ),

                                              ),

                                              //------------------------------------------------------------------------------

                                              // ORAL SEX TAG
                                              if (oral_sex_tag_object.show_tag)

                                                Container(

                                                  // PADDING
                                                  padding: EdgeInsets.all(7),

                                                  //CONTAINER STYLE
                                                  decoration: BoxDecoration(

                                                    // BACKGROUND COLOR
                                                    color: oral_sex_tag_object.background_color,

                                                    // BORDER RADIUS
                                                    borderRadius: BorderRadius.circular(16),

                                                    // BORDER STYLE
                                                    border: Border.all(
                                                      color: oral_sex_tag_object.background_color,
                                                      width: 1,
                                                    ),

                                                  ),

                                                  // CONTAINER CONTENT
                                                  child: Text(

                                                    // TEXT
                                                    oral_sex_tag_object.label,

                                                    // TEXT STYLE
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),

                                                  ),

                                                ),

                                              //------------------------------------------------------------------------------

                                              // ANAL SEX TAG
                                              if (anal_sex_tag_object.show_tag)
                                                Container(

                                                  // PADDING
                                                  padding: EdgeInsets.all(7),

                                                  //CONTAINER STYLE
                                                  decoration: BoxDecoration(

                                                    // BACKGROUND COLOR
                                                    color: anal_sex_tag_object.background_color,

                                                    // BORDER RADIUS
                                                    borderRadius: BorderRadius.circular(16),

                                                    // BORDER STYLE
                                                    border: Border.all(
                                                      color: anal_sex_tag_object.background_color,
                                                      width: 1,
                                                    ),

                                                  ),

                                                  // CONTAINER CONTENT
                                                  child: Text(

                                                    // TEXT
                                                    anal_sex_tag_object.label,

                                                    // TEXT STYLE
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),

                                                  ),

                                                ),

                                              //------------------------------------------------------------------------------

                                              // VAGINAL SEX TAG
                                              if (vaginal_sex_tag_object.show_tag)
                                                Container(

                                                  // PADDING
                                                  padding: EdgeInsets.all(7),

                                                  //CONTAINER STYLE
                                                  decoration: BoxDecoration(

                                                    // BACKGROUND COLOR
                                                    color: vaginal_sex_tag_object.background_color,

                                                    // BORDER RADIUS
                                                    borderRadius: BorderRadius.circular(16),

                                                    // BORDER STYLE
                                                    border: Border.all(
                                                      color: vaginal_sex_tag_object.background_color,
                                                      width: 1,
                                                    ),

                                                  ),

                                                  // CONTAINER CONTENT
                                                  child: Text(

                                                    // TEXT
                                                    vaginal_sex_tag_object.label,

                                                    // TEXT STYLE
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),

                                                  ),

                                                ),

                                              //------------------------------------------------------------------------------

                                              // BONDAGE SEX TAG
                                              if (bondage_tag_object.show_tag)
                                                Container(

                                                  // PADDING
                                                  padding: EdgeInsets.all(7),

                                                  //CONTAINER STYLE
                                                  decoration: BoxDecoration(

                                                    // BACKGROUND COLOR
                                                    color: bondage_tag_object.background_color,

                                                    // BORDER RADIUS
                                                    borderRadius: BorderRadius.circular(16),

                                                    // BORDER STYLE
                                                    border: Border.all(
                                                      color: bondage_tag_object.background_color,
                                                      width: 1,
                                                    ),

                                                  ),

                                                  // CONTAINER CONTENT
                                                  child: Text(

                                                    // TEXT
                                                    bondage_tag_object.label,

                                                    // TEXT STYLE
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),

                                                  ),

                                                ),

                                              //------------------------------------------------------------------------------

                                              // BDSM SEX TAG
                                              if (bdsm_tag_object.show_tag)
                                                Container(

                                                  // PADDING
                                                  padding: EdgeInsets.all(7),

                                                  //CONTAINER STYLE
                                                  decoration: BoxDecoration(

                                                    // BACKGROUND COLOR
                                                    color: bdsm_tag_object.background_color,

                                                    // BORDER RADIUS
                                                    borderRadius: BorderRadius.circular(16),

                                                    // BORDER STYLE
                                                    border: Border.all(
                                                      color: bdsm_tag_object.background_color,
                                                      width: 1,
                                                    ),

                                                  ),

                                                  // CONTAINER CONTENT
                                                  child: Text(

                                                    // TEXT
                                                    bdsm_tag_object.label,

                                                    // TEXT STYLE
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),

                                                  ),

                                                ),

                                              //------------------------------------------------------------------------------

                                              // CHAT SEX TAG
                                              if (chat_tag_object.show_tag)
                                                Container(

                                                  // PADDING
                                                  padding: EdgeInsets.all(7),

                                                  //CONTAINER STYLE
                                                  decoration: BoxDecoration(

                                                    // BACKGROUND COLOR
                                                    color: chat_tag_object.background_color,

                                                    // BORDER RADIUS
                                                    borderRadius: BorderRadius.circular(16),

                                                    // BORDER STYLE
                                                    border: Border.all(
                                                      color: chat_tag_object.background_color,
                                                      width: 1,
                                                    ),

                                                  ),

                                                  // CONTAINER CONTENT
                                                  child: Text(

                                                    // TEXT
                                                    chat_tag_object.label,

                                                    // TEXT STYLE
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),

                                                  ),

                                                ),

                                              //------------------------------------------------------------------------------

                                              // VIDEO SEX TAG
                                              if (video_call_tag_object.show_tag)
                                                Container(

                                                  // PADDING
                                                  padding: EdgeInsets.all(7),

                                                  //CONTAINER STYLE
                                                  decoration: BoxDecoration(

                                                    // BACKGROUND COLOR
                                                    color: video_call_tag_object.background_color,

                                                    // BORDER RADIUS
                                                    borderRadius: BorderRadius.circular(16),

                                                    // BORDER STYLE
                                                    border: Border.all(
                                                      color: video_call_tag_object.background_color,
                                                      width: 1,
                                                    ),

                                                  ),

                                                  // CONTAINER CONTENT
                                                  child: Text(

                                                    // TEXT
                                                    video_call_tag_object.label,

                                                    // TEXT STYLE
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),

                                                  ),

                                                ),

                                              //------------------------------------------------------------------------------


                                            ],

                                          ),

                                          //------------------------------------------------------------------------------

                                        ],

                                      ),

                                    ),

                                    // ARROW ICON
                                    Icon(

                                      // ICON IMAGE
                                      Icons.arrow_forward,

                                      // ICON COLOR
                                      color: Theme.of(context).colorScheme.onPrimary,

                                    )

                                  ],

                                ),

                              ),

                              //------------------------------------------------------------------------------

                            ),

                            // SPACER
                            const SizedBox(height: 15),

                          ],

                        ),

                      );



                    },

                    // GETTING THE LIST ELEMENT
                    childCount: filtered_decks_list.length,

                  ),

                  //------------------------------------------------------------------------------

                ),

                //------------------------------------------------------------------------------

              ],

            ),

          ),

        ),

      ),

    );

    //------------------------------------------------------------------------------

  }



  //------------------------------------------------------------------------------

}












