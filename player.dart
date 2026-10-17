import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MxOriginalUiApp());
}

class MxOriginalUiApp extends StatelessWidget {
  const MxOriginalUiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MX Player',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF0057D9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0057D9),
          elevation: 2,
        ),
      ),
      home: const MxMainShell(),
    );
  }
}

class VideoItem {
  final String title;
  final String path;
  final String folder;
  final String size;
  final String resolution;
  final bool isNetwork;
  final bool isNew;

  VideoItem({
    required this.title,
    required this.path,
    required this.folder,
    required this.size,
    this.resolution = '1080p',
    this.isNetwork = false,
    this.isNew = true,
  });
}

class MxMainShell extends StatefulWidget {
  const MxMainShell({super.key});

  @override
  State<MxMainShell> createState() => _MxMainShellState();
}

class _MxMainShellState extends State<MxMainShell> {
  bool _isGridView = false;
  bool _isDarkTheme = true;
  String? _selectedFolder;

  final List<VideoItem> _allVideos = [
    VideoItem(
      title: 'Big_Buck_Bunny_1080p_BluRay_x264.mp4',
      path: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      folder: 'Movies',
      size: '158 MB',
      resolution: '1080p',
      isNetwork: true,
      isNew: true,
    ),
    VideoItem(
      title: 'Sintel_4K_Dolby_Atmos_Dual_Audio.mkv',
      path: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
      folder: 'Movies',
      size: '412 MB',
      resolution: '4K UHD',
      isNetwork: true,
      isNew: false,
    ),
    VideoItem(
      title: 'For_Bigger_Blazes_Sample_Status.mp4',
      path: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      folder: 'WhatsApp Video',
      size: '14.2 MB',
      resolution: '720p',
      isNetwork: true,
      isNew: true,
    ),
    VideoItem(
      title: 'Elephants_Dream_Action_Clip.mp4',
      path: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      folder: 'Download',
      size: '84.5 MB',
      resolution: '1080p',
      isNetwork: true,
      isNew: true,
    ),
  ];

  Map<String, List<VideoItem>> get _groupedFolders {
    final Map<String, List<VideoItem>> map = {};
    for (var v in _allVideos) {
      map.putIfAbsent(v.folder, () => []).add(v);
    }
    return map;
  }

  Future<void> _pickDeviceVideos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (var f in result.files) {
          if (f.path != null) {
            final mb = (f.size / (1024 * 1024)).toStringAsFixed(1);
            final parts = f.path!.split('/');
            final folderName = parts.length > 2 ? parts[parts.length - 2] : 'Internal Storage';
            _allVideos.insert(
              0,
              VideoItem(
                title: f.name,
                path: f.path!,
                folder: folderName,
                size: '$mb MB',
                resolution: 'HD',
                isNetwork: false,
                isNew: true,
              ),
            );
          }
        }
      });
    }
  }

  void _openNetworkStreamDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkTheme ? const Color(0xFF222222) : Colors.white,
        title: Text(
          'Network Stream',
          style: TextStyle(color: _isDarkTheme ? Colors.white : Colors.black),
        ),
        content: TextField(
          controller: ctrl,
          style: TextStyle(color: _isDarkTheme ? Colors.white : Colors.black),
          decoration: const InputDecoration(
            labelText: 'Enter network URL',
            hintText: 'https://example.com/movie.mp4',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0057D9)),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                final url = ctrl.text.trim();
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MxVideoPlayerScreen(
                      video: VideoItem(
                        title: url.split('/').last,
                        path: url,
                        folder: 'Stream',
                        size: 'LIVE',
                        isNetwork: true,
                      ),
                    ),
                  ),
                );
              }
            },
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkTheme ? const Color(0xFF121212) : const Color(0xFFF5F6F8);
    final cardColor = _isDarkTheme ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = _isDarkTheme ? Colors.white : Colors.black87;
    final subTextColor = _isDarkTheme ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      drawer: _buildMxDrawer(textColor, cardColor),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0057D9),
        leading: _selectedFolder != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _selectedFolder = null),
              )
            : null,
        title: _selectedFolder != null
            ? Text(
                _selectedFolder!,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white),
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.play_arrow, color: Color(0xFF0057D9), size: 18),
                        Text(
                          'MX',
                          style: TextStyle(
                            color: Color(0xFF0057D9),
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Player',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 19),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _pickDeviceVideos,
            tooltip: 'Scan / Add Videos',
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, color: Colors.white),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: 'Switch View',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: cardColor,
            onSelected: (val) {
              if (val == 'stream') _openNetworkStreamDialog();
              if (val == 'add') _pickDeviceVideos();
              if (val == 'theme') setState(() => _isDarkTheme = !_isDarkTheme);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'add',
                child: Row(
                  children: [
                    Icon(Icons.create_new_folder_outlined, color: textColor, size: 20),
                    const SizedBox(width: 12),
                    Text('Import Local Videos', style: TextStyle(color: textColor)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'stream',
                child: Row(
                  children: [
                    Icon(Icons.cloud_queue, color: textColor, size: 20),
                    const SizedBox(width: 12),
                    Text('Network Stream', style: TextStyle(color: textColor)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined, color: textColor, size: 20),
                    const SizedBox(width: 12),
                    Text(_isDarkTheme ? 'Light Theme' : 'Dark Theme', style: TextStyle(color: textColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _selectedFolder == null
          ? _buildFolderView(textColor, subTextColor, cardColor)
          : _buildVideoListView(_groupedFolders[_selectedFolder!] ?? [], textColor, subTextColor, cardColor),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0057D9),
        onPressed: () {
          if (_allVideos.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MxVideoPlayerScreen(video: _allVideos.first)),
            );
          }
        },
        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: cardColor,
        selectedItemColor: const Color(0xFF0057D9),
        unselectedItemColor: subTextColor,
        currentIndex: 0,
        onTap: (idx) {
          if (idx == 0) setState(() => _selectedFolder = null);
          if (idx == 1) _pickDeviceVideos();
          if (idx == 2) _openNetworkStreamDialog();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.folder_rounded), label: 'Local'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library_rounded), label: 'Add Videos'),
          BottomNavigationBarItem(icon: Icon(Icons.language_rounded), label: 'Stream'),
        ],
      ),
    );
  }

  Widget _buildFolderView(Color textColor, Color subTextColor, Color cardColor) {
    final folders = _groupedFolders.entries.toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: cardColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Folders (${folders.length})',
                style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              InkWell(
                onTap: _pickDeviceVideos,
                child: const Row(
                  children: [
                    Icon(Icons.add_circle, color: Color(0xFF0057D9), size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Select Videos from Phone',
                      style: TextStyle(color: Color(0xFF0057D9), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white12),
        Expanded(
          child: _isGridView
              ? GridView.builder(
                  padding: const EdgeInsets.all(14),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final entry = folders[index];
                    return InkWell(
                      onTap: () => setState(() => _selectedFolder = entry.key),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              const Icon(Icons.folder_rounded, color: Color(0xFFFFB703), size: 68),
                              Positioned(
                                right: 4,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${entry.value.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            entry.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : ListView.separated(
                  itemCount: folders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 76, color: Colors.white10),
                  itemBuilder: (context, index) {
                    final entry = folders[index];
                    final hasNew = entry.value.any((v) => v.isNew);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.folder_rounded, color: Color(0xFF4285F4), size: 48),
                          if (hasNew)
                            Positioned(
                              right: -4,
                              top: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        entry.key,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      subtitle: Text(
                        '${entry.value.length}${entry.value.length == 1 ? "video" : "videos"}',
                        style: TextStyle(color: subTextColor, fontSize: 13),
                      ),
                      trailing: Icon(Icons.chevron_right, color: subTextColor),
                      onTap: () => setState(() => _selectedFolder = entry.key),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVideoListView(List<VideoItem> videos, Color textColor, Color subTextColor, Color cardColor) {
    return ListView.separated(
      itemCount: videos.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 118, color: Colors.white10),
      itemBuilder: (context, index) {
        final v = videos[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MxVideoPlayerScreen(video: v)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 96,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1F2B3E), Color(0xFF0D131D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 28),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            v.resolution,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 14.5),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (v.isNew)
                            Container(
                              margin: const EdgeInsets.only(rig
