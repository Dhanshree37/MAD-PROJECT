import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dance Style Music Recommender',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DanceStyleSelector(),
    );
  }
}

class DanceStyleSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose a Dance Style'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DanceStyleGrid(),
      ),
    );
  }
}

class DanceStyleGrid extends StatelessWidget {
  final List<Map<String, dynamic>> danceStyles = [
    {
      'name': 'salsa',
      'image': 'salsa.jpg',
      'description':
          'Salsa is a lively, sensual dance that originated in the Caribbean. It is characterized by intricate footwork and rhythmic hip movements.'
    },
    {
      'name': 'ballet',
      'image': 'ballet.jpg',
      'description':
          'Ballet is a classical dance form that emphasizes grace, precision, and technique. It is known for its elaborate costumes, music, and storytelling through dance.'
    },
    {
      'name': 'hiphop',
      'image': 'hip_hop.jpg',
      'description':
          'Hip Hop is a cultural movement that includes various elements such as rap music, DJing, graffiti art, and of course, dance. Hip Hop dance styles encompass a wide range of movements and expression.'
    },
    {
      'name': 'tapdance',
      'image': 'tap_dance.jpg',
      'description':
          'Tap Dance is characterized by the use of tap shoes, which have metal plates on the sole that create rhythmic sounds when struck against the floor. It combines elements of dance and percussion.'
    },
    {
      'name': 'indian',
      'image': 'bollywood.jpg',
      'description':
          'Bollywood dance is a fusion of various Indian dance styles with elements of Western dance forms. It is often colorful, energetic, and expressive, and is commonly seen in Indian films.'
    },
    {
      'name': 'breakdance',
      'image': 'breakdance.jpg',
      'description':
          'Breakdance, also known as B-boying or B-girling, is a form of street dance that originated among African American and Latino youth in New York City. It is characterized by its acrobatic moves and improvisational style.'
    },
    {
      'name': 'bellydance',
      'image': 'belly_dance.jpg',
      'description':
          'Belly Dance, also known as Middle Eastern dance, is an expressive dance form that emphasizes isolations of the hips and abdomen. It is often performed at celebrations and social gatherings.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
      ),
      itemCount: danceStyles.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // When a dance style is tapped, navigate to the RecommendedSongsScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecommendedSongsScreen(
                  danceStyle: danceStyles[index]['name'],
                  description: danceStyles[index]['description'],
                ),
              ),
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  image: DecorationImage(
                    image: AssetImage(danceStyles[index]['image']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.black.withOpacity(0.5),
                ),
                child: Center(
                  child: Text(
                    danceStyles[index]['name'],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class RecommendedSongsScreen extends StatefulWidget {
  final String danceStyle;
  final String description;

  RecommendedSongsScreen({
    required this.danceStyle,
    required this.description,
  });

  @override
  _RecommendedSongsScreenState createState() => _RecommendedSongsScreenState();
}

class _RecommendedSongsScreenState extends State<RecommendedSongsScreen> {
  List<dynamic> _recommendedSongs = [];

  @override
  void initState() {
    super.initState();
    _fetchRecommendedSongs();
  }

  Future<void> _fetchRecommendedSongs() async {
    // Make HTTP request to the Flask server for recommendations
    Uri url = Uri.parse('http://127.0.0.1:5000/recommendations/${widget.danceStyle}');

    // Include dance style in the URL
    var response = await http.post(
      url,
      body: {'dance_style': widget.danceStyle},
    );

    if (response.statusCode == 200) {
      List<dynamic> recommendedSongs = json.decode(response.body)['recommended_songs'];

      // Flatten the list of recommended songs
      List<Map<String, String>> songsList = [];
      recommendedSongs.forEach((list) {
        list.forEach((song) {
          songsList.add({
            'album': song['album'],
            'artists': song['artists'],
            'song_name': song['song_name'],
          });
        });
      });

      setState(() {
        // Set the flattened list of recommended songs
        _recommendedSongs = songsList;
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to fetch recommendations. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }





@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Recommended Songs'),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with dance style and brief paragraph
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Brief paragraph about the dance style
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          // List of recommended songs wrapped with Expanded
          Expanded(
            child: Scrollbar(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _recommendedSongs.map<Widget>((song) {
                    // Display song information
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.purple.shade300),
                        ),
                        color: Colors.purple.shade50,
                      ),
                      child: ListTile(
                        title: Text(song['song_name']),
                        subtitle: Text(song['artists'] + ' - ' + song['album']),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

}