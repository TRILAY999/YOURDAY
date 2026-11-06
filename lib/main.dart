
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const String feedUrl =
    'https://xnxxvdeoss.blogspot.com/feeds/posts/default?alt=rss&max-results=50';

// Google AdMob Test Banner ID
const String bannerTestId =
    'ca-app-pub-3940256099942544/6300978111';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const YourDayApp());
}

class XNXXVIDEOSApp extends StatelessWidget {
  const xnxxvideosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOURDAY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class BlogPost {
  final String title;
  final String link;
  final String image;

  BlogPost(this.title, this.link, this.image);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<BlogPost>> postsFuture;

  @override
  void initState() {
    super.initState();
    postsFuture = loadPosts();
  }

  Future<List<BlogPost>> loadPosts() async {
    final response = await http.get(Uri.parse(feedUrl));

    if (response.statusCode != 200) {
      throw Exception('Cannot load Blogger posts');
    }

    final document = xml.XmlDocument.parse(response.body);
    final items = document.findAllElements('item');

    return items.map((item) {
      final title =
          item.getElement('title')?.innerText ?? 'No title';

      final link =
          item.getElement('link')?.innerText ?? '';

      final description =
          item.getElement('description')?.innerText ?? '';

      final imageMatch = RegExp(
        r'''<img[^>]+src=["']([^"']+)''',
        caseSensitive: false,
      ).firstMatch(description);

      final image = imageMatch?.group(1) ?? '';

      return BlogPost(title, link, image);
    }).where((post) => post.link.isNotEmpty).toList();
  }

  void refreshPosts() {
    setState(() {
      postsFuture = loadPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'YOURDAY',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: FutureBuilder<List<BlogPost>>(
        future: postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, size: 50),
                  const SizedBox(height: 12),
                  const Text(
                    'មិនអាចទាញយកទិន្នន័យបានទេ',
                  ),
                  ElevatedButton(
                    onPressed: refreshPosts,
                    child: const Text('សាកល្បងម្ដងទៀត'),
                  ),
                ],
              ),
            );
          }

          final posts = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: () async {
              refreshPosts();
              await postsFuture;
            },
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),

                    leading: post.image.isNotEmpty
                        ? Image.network(
                            post.image,
                            width: 75,
                            height: 75,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return const Icon(
                                Icons.video_library,
                                size: 45,
                              );
                            },
                          )
                        : const Icon(
                            Icons.video_library,
                            size: 45,
                          ),

                    title: Text(
                      post.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    subtitle: const Text(
                      'ចុចដើម្បីមើលវីដេអូ',
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPage(
                            url: post.link,
                            title: post.title,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),

      bottomNavigationBar: const AdBanner(),
    );
  }
}

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? banner;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();

    banner = BannerAd(
      adUnitId: bannerTestId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          banner = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoaded || banner == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 50,
      child: AdWidget(ad: banner!),
    );
  }
}

class VideoPage extends StatefulWidget {
  final String url;
  final String title;

  const VideoPage({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(
        JavaScriptMode.unrestricted,
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: WebViewWidget(
        controller: controller,
      ),
    );
  }
}