import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jraduanffritvfwogtmn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpyYWR1YW5mZnJpdHZmd29ndG1uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTUwMDA2NjEsImV4cCI6MjAzMDU3NjY2MX0.fgmHAnntB1VpfhOSFWJtRpW-_r2-GmI5NDuUdFbdRI8',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Youtube',
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Text("VIDEOS"),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: VideoSearchDelegate());
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: Supabase.instance.client.from('videos').select(),
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final videos = snapshot.data as List<dynamic>?;
            if (videos == null || videos.isEmpty) {
              return Center(child: Text('No videos available'));
            }
            return ListView.builder(
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return VideoListItem(video: video);
              },
            );
          }
        },
      ),
    );
  }
}

class VideoSearchDelegate extends SearchDelegate<List<dynamic>> {
  @override
  String get searchFieldLabel => 'Search videos';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, []);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: Text('Search results for: $query'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: TextField(
            controller: TextEditingController(text: query),
            onChanged: (value) {
              query = value;
            },
            decoration: InputDecoration(
              hintText: 'Search...',
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  // Perform search here
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder(
            future: fetchVideos(query),
            builder: (context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                final videos = snapshot.data as List<dynamic>?;
                if (videos == null || videos.isEmpty) {
                  return Center(child: Text('No videos available'));
                }
                return ListView.builder(
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return VideoListItem(video: video);
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Future<List<dynamic>> fetchVideos(String query) async {
    // Fetch videos from the database with optional search filter
    return await Supabase.instance.client
        .from('videos')
        .select()
        .ilike('title', '%$query%');
  }
}


class VideoListItem extends StatelessWidget {
  final dynamic video;

  const VideoListItem({Key? key, required this.video}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String videoUrl = video['url'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(video['title']),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              YoutubePlayerWidget(url: videoUrl),
              Text('Likes: '+video['likes'].toString()),
              Text('\nDescription: '+ video['description']),
              //ClickableUrlWidget(url: videoUrl),
            ],
          ),
        ),
      ],
    );
  }
}

class YoutubePlayerWidget extends StatelessWidget{
  final String? url;
  YoutubePlayerWidget({this.url});

  RegExp regExp = RegExp(r'^https?:\/\/(?:www\.)?youtube\.com\/.*[&?]v=([^&]+)');
  
  Widget build(context){
    String? videoId = regExp.firstMatch(url.toString())?.group(1);
    return YoutubePlayer(
      controller: YoutubePlayerController(
        initialVideoId: videoId.toString(),
        flags: YoutubePlayerFlags(
          autoPlay: true,
          mute: true,
        ),
      ),
      showVideoProgressIndicator: true,
    );
  }
}

class SearchBarWidget extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return SearchBarWidgetState();
  }
}

class SearchBarWidgetState extends State<SearchBarWidget>{
  TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  Widget build(BuildContext context){
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search...',
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: (){
                  setState(() {
                    _searchText = _searchController.text;
                  });
                },
              ),
            ),
            onChanged: (value){
              setState(() {
                _searchText = value;
              });
            },
          ),
        ),
        Expanded(
          child: FutureBuilder(
            future: fetchVideos(),
            builder: (context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                final videos = snapshot.data as List<dynamic>?;
                if (videos == null || videos.isEmpty) {
                  return Center(child: Text('No videos available'));
                }
                return ListView.builder(
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return VideoListItem(video: video);
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Future<List<dynamic>> fetchVideos() async {
    // Fetch videos from the database with optional search filter
    return await Supabase.instance.client
        .from('videos')
        .select()
        .ilike('title', '%$_searchText%');
  }
}

