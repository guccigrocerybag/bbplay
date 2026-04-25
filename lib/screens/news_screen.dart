import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/video_player_widget.dart'; // <--- Подключаем наш плеер

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  // ТВОЙ СЕРВИСНЫЙ КЛЮЧ
  final String _token = 'd2fba78fd2fba78fd2fba78f7ed1bbdf24dd2fbd2fba78fbb1cdc3939ab3775cb81234d'; 
  final String _groupDomain = 'bbplay__tmb'; 

  final List<Map<String, dynamic>> _fallbackPosts =[
    {
      'text': '🎮 Добро пожаловать в BBplay! \n\nСледите за новостями в нашем сообществе VK. Здесь будут появляться актуальные новости, турниры и акции.',
      'date': 1713600000,
      'owner_id': -211993439, 'id': 1
    },
  ];

  Future<List<dynamic>> _fetchVkNews() async {
    try {
      final url = Uri.parse('https://api.vk.com/method/wall.get?domain=$_groupDomain&filter=owner&count=10&v=5.131&access_token=$_token');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] != null) throw Exception(data['error']['error_msg']);
        if (data['response'] != null) return data['response']['items'];
      }
      throw Exception('Network error');
    } catch (e) {
      return _fallbackPosts; 
    }
  }

  // --- ЛОГИКА ОПРЕДЕЛЕНИЯ МЕДИА (ВИДЕО ИЛИ ФОТО) ---
  Map<String, dynamic>? _getMediaData(Map<String, dynamic> post) {
    try {
      final attachments = post['attachments'];
      if (attachments == null || attachments.isEmpty) return null;

      final first = attachments[0];
      final type = first['type'];

      if (type == 'photo') {
        final sizes = first['photo']['sizes'];
        final largest = sizes.lastWhere((s) => s['type'] == 'z' || s['type'] == 'y' || s['type'] == 'x', orElse: () => sizes.last);
        return {'url': largest['url'], 'isVideo': false};
      }

      if (type == 'video') {
        final video = first['video'];
        final image = video['image']?.lastWhere((img) => img['width'] >= 800, orElse: () => video['image']?.last);
        return {'url': image?['url'] ?? '', 'isVideo': true, 'videoId': '${video['owner_id']}_${video['id']}'};
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // --- ОБРАБОТКА КЛИКА НА НОВОСТЬ ---
  void _handleMediaTap(Map<String, dynamic> post) async {
    // Собираем ссылку на пост VK: https://vk.com/wall{owner_id}_{id}
    final ownerId = post['owner_id'];
    final postId = post['id'];
    final vkPostUrl = 'https://vk.com/wall${ownerId}_$postId';

    final media = _getMediaData(post);

    if (media != null && media['isVideo'] == true) {
      // Открываем видео в модальном окне
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          contentPadding: EdgeInsets.zero,
          content: VideoPlayerScreen(embedUrl: 'https://vk.com/video${media['videoId']}'),
        ),
      );
    } else {
      // Открываем пост VK в браузере
      final url = Uri.parse(vkPostUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final settings = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(settings.getText('news'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchVkNews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading(colorScheme);
          }

          final posts = snapshot.data ?? _fallbackPosts;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            color: colorScheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final String text = post['text'] ?? '';
                final media = _getMediaData(post);

                if (text.isEmpty && media == null) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF2A313A) : colorScheme.outline.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _handleMediaTap(post), // <--- Обработка клика
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        if (media != null && media['url'].toString().isNotEmpty)
                          Stack(
                            alignment: Alignment.center,
                            children:[
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: Image.network(
                                  media['url'],
                                  width: double.infinity,
                                  fit: BoxFit.fitWidth, // Идеально вписывает по ширине!
                                  errorBuilder: (context, e, s) => const SizedBox.shrink(),
                                ),
                              ),
                              if (media['isVideo'] == true)
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(FontAwesomeIcons.play, color: Colors.white, size: 24),
                                ),
                            ],
                          ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children:[
                                  Text(_formatDate(post['date']), style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                text,
                                style: TextStyle(color: colorScheme.onSurface, fontSize: 14, height: 1.5),
                                maxLines: 6,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(media?['isVideo'] == true ? settings.getText('watch_video') : settings.getText('read_more'), style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios, size: 10, color: colorScheme.onSurface.withOpacity(0.6)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Скелетон-загрузка с эффектом Shimmer для новостей
  Widget _buildShimmerLoading(ColorScheme colorScheme) {
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceVariant.withOpacity(0.5),
      highlightColor: colorScheme.surfaceVariant.withOpacity(0.8),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Изображение
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
                // Текст
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 100, color: Colors.white),
                      const SizedBox(height: 12),
                      Container(height: 14, width: double.infinity, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 14, width: double.infinity, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 14, width: 150, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(int ts) {
    var d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";
  }
}