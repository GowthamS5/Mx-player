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
          backgroundColor: Color(0xFF0057D9), // Classic MX Blue
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
  String? _selectedFolder; // null = Show Folders List, non-null = Show Videos inside Folder

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
            // Extract parent folder name just like MX Player
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
            hintText: 'https://example.com/movie.mkv',
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

    return PopScope(
      canPop: _selectedFolder == null,
      onPopInvoked: (didPop) {
        if (!didPop && _selectedFolder != null) {
          setState(() => _selectedFolder = null);
        }
      },
      child: Scaffold(
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
                    // Classic MX Logo Badge
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
                      Icon(Icons.cloud_Queue, color: textColor, size: 20),
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
            // Play last played or add video
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
            if (idx == 1) _pickDeviceVideos();
            if (idx == 2) _openNetworkStreamDialog();
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.folder_rounded), label: 'Local'),
            BottomNavigationBarItem(icon: Icon(Icons.video_library_rounded), label: 'Add Videos'),
            BottomNavigationBarItem(icon: Icon(Icons.language_rounded), label: 'Stream'),
          ],
        ),
      ),
    );
  }

  // ==================== 1. MX PLAYER FOLDER LIST / GRID UI ====================
  Widget _buildFolderView(Color textColor, Color subTextColor, Color cardColor) {
    final folders = _groupedFolders.entries.toList();

    return Column(
      children: [
        // Top Quick Action Strip (Just like MX Player Local Tab)
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
                        '${entry.value.length} ${entry.value.length == 1 ? "video" : "videos"}',
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

  // ==================== 2. MX PLAYER VIDEO FILES LIST UI ====================
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
                // Classic MX 16:9 Thumbnail Box with Duration Tag
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
                // Video Title + New Badge + File Size
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
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0057D9),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          Text(
                            v.size,
                            style: TextStyle(color: subTextColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: subTextColor, size: 20),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== 3. MX PLAYER SIDE DRAWER ====================
  Widget _buildMxDrawer(Color textColor, Color cardColor) {
    return Drawer(
      backgroundColor: cardColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20),
            color: const Color(0xFF0057D9),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.play_arrow_rounded, color: Color(0xFF0057D9), size: 40),
                ),
                SizedBox(height: 12),
                Text(
                  'MX Player Pro',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '100% Ad-Free Edition',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.folder_open, color: textColor),
            title: Text('Local Player Settings', style: TextStyle(color: textColor)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.cloud_Queue, color: textColor),
            title: Text('Network Stream', style: TextStyle(color: textColor)),
            onTap: () {
              Navigator.pop(context);
              _openNetworkStreamDialog();
            },
          ),
          ListTile(
            leading: Icon(Icons.dark_mode_outlined, color: textColor),
            title: Text('Dark / Light Theme', style: TextStyle(color: textColor)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _isDarkTheme = !_isDarkTheme);
            },
          ),
        ],
      ),
    );
  }
}

// ==================== 4. EXACT MX VIDEO PLAYER SCREEN UI ====================
class MxVideoPlayerScreen extends StatefulWidget {
  final VideoItem video;
  const MxVideoPlayerScreen({super.key, required this.video});

  @override
  State<MxVideoPlayerScreen> createState() => _MxVideoPlayerScreenState();
}

class _MxVideoPlayerScreenState extends State<MxVideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showHud = true;
  bool _isLocked = false;
  bool _isHwPlus = true;
  bool _isLandscape = true;
  bool _is2xSpeedHold = false;

  double _brightness = 0.85;
  double _volume = 0.85;
  double _speed = 1.0;
  int _aspectMode = 0; // 0: Fit, 1: Crop, 2: Stretch

  String? _activeSliderType; // 'volume' or 'brightness' or 'seek'
  String _centerSeekText = '';
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _applyOrientation(true);
    _initController();
  }

  Future<void> _applyOrientation(bool landscape) async {
    _isLandscape = landscape;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (landscape) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  Future<void> _initController() async {
    _controller = widget.video.isNetwork
        ? VideoPlayerController.networkUrl(Uri.parse(widget.video.path))
        : VideoPlayerController.file(File(widget.video.path));

    await _controller.initialize();
    await _controller.setVolume(_volume);
    await _controller.play();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    setState(() => _initialized = true);
    _resetHideTimer();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showHud = false);
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  BoxFit _getVideoFit() {
    if (_aspectMode == 1) return BoxFit.cover;
    if (_aspectMode == 2) return BoxFit.fill;
    return BoxFit.contain;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() => _showHud = !_showHud);
          if (_showHud) _resetHideTimer();
        },
        onDoubleTap: () {
          if (_isLocked || !_initialized) return;
          setState(() {
            _controller.value.isPlaying ? _controller.pause() : _controller.play();
          });
        },
        onLongPressStart: (_) {
          if (_isLocked || !_initialized) return;
          _controller.setPlaybackSpeed(2.0);
          setState(() => _is2xSpeedHold = true);
        },
        onLongPressEnd: (_) {
          if (_isLocked || !_initialized) return;
          _controller.setPlaybackSpeed(_speed);
          setState(() => _is2xSpeedHold = false);
        },
        onVerticalDragUpdate: (details) {
          if (_isLocked) return;
          final isLeft = details.globalPosition.dx < width / 2;
          final delta = -details.primaryDelta! / 200;
          setState(() {
            if (isLeft) {
              _brightness = (_brightness + delta).clamp(0.05, 1.0);
              _activeSliderType = 'brightness';
            } else {
              _volume = (_volume + delta).clamp(0.0, 1.0);
              _controller.setVolume(_volume);
              _activeSliderType = 'volume';
            }
          });
        },
        onVerticalDragEnd: (_) => setState(() => _activeSliderType = null),
        onHorizontalDragUpdate: (details) {
          if (_isLocked || !_initialized) return;
          final offsetSec = (details.primaryDelta! * 0.45).round();
          final target = _controller.value.position + Duration(seconds: offsetSec);
          _controller.seekTo(target);
          setState(() {
            _activeSliderType = 'seek';
            _centerSeekText = '[ ${_fmt(_controller.value.position)} ]';
          });
        },
        onHorizontalDragEnd: (_) => setState(() => _activeSliderType = null),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video Output
            if (_initialized)
              Center(
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: _getVideoFit(),
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
              )
            else
              const Center(child: CircularProgressIndicator(color: Color(0xFF0057D9))),

            // Brightness Dimmer Layer
            IgnorePointer(
              child: Container(color: Colors.black.withOpacity((1.0 - _brightness) * 0.8)),
            ),

            // MX Style Vertical Brightness / Volume Bar
            if (_activeSliderType == 'brightness' || _activeSliderType == 'volume')
              Center(
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _activeSliderType == 'brightness' ? Icons.brightness_6_rounded : Icons.volume_up_rounded,
                        color: const Color(0xFF0078FF),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _activeSliderType == 'brightness' ? _brightness : _volume,
                        backgroundColor: Colors.white24,
                        color: const Color(0xFF0078FF),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${((_activeSliderType == 'brightness' ? _brightness : _volume) * 15).round()} / 15',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

            // MX Style Horizontal Seek Text in Center
            if (_activeSliderType == 'seek')
              Center(
                child: Text(
                  _centerSeekText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                  ),
                ),
              ),

            // 2x Fast Play Top Pill
            if (_is2xSpeedHold)
              Positioned(
                top: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                    child: const Text('2.0x Speed  ⏩', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),

            // Locked Screen Icon Only
            if (_showHud && _isLocked)
              Positioned(
                top: 24,
                left: 24,
                child: IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.black87, padding: const EdgeInsets.all(12)),
                  icon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF0078FF), size: 28),
                  onPressed: () => setState(() => _isLocked = false),
                ),
              ),

            // ==================== ORIGINAL MX PLAYER TOP & BOTTOM BARS ====================
            if (_showHud && !_isLocked && _initialized)
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. TOP MX ACTION BAR (Back, Title, HW+, Audio, Subtitle, Speed, Menu)
                  Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              widget.video.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                          // Iconic MX Player "HW+" Decoder Button
                          InkWell(
                            onTap: () => setState(() => _isHwPlus = !_isHwPlus),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white70),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _isHwPlus ? 'HW+' : 'SW',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                          // Speed Toggle
                          TextButton(
                            onPressed: () {
                              final list = [0.5, 1.0, 1.25, 1.5, 2.0];
                              final next = list[(list.indexOf(_speed) + 1) % list.length];
                              setState(() => _speed = next);
                              _controller.setPlaybackSpeed(next);
                            },
                            child: Text('${_speed}x', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          // Audio Track Icon
                          IconButton(
                            icon: const Icon(Icons.music_note_outlined, color: Colors.white, size: 22),
                            tooltip: 'Audio Track',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Audio Track: Track 1 (Stereo) Selected')),
                              );
                            },
                          ),
                          // Subtitles Icon
                          IconButton(
                            icon: const Icon(Icons.subtitles_outlined, color: Colors.white, size: 22),
                            tooltip: 'Subtitles',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Subtitles: None Found')),
                              );
                            },
                          ),
                          // Rotate Icon
                          IconButton(
                            icon: const Icon(Icons.screen_rotation_outlined, color: Colors.white, size: 20),
                            onPressed: () => _applyOrientation(!_isLandscape),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. BOTTOM MX SEEKBAR & TRANSPORT BAR (Lock, Prev, Play/Pause, Next, Aspect Ratio)
                  Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.only(left: 14, right: 14, bottom: 8, top: 4),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Seekbar Row
                          Row(
                            children: [
                              Text(
                                _fmt(_controller.value.position),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                  ),
                                  child: Slider(
                                    activeColor: const Color(0xFF0078FF),
                                    inactiveColor: Colors.white30,
                                    value: _controller.value.position.inSeconds.toDouble().clamp(
                                          0,
                                          _controller.value.duration.inSeconds.toDouble(),
                                        ),
                                    max: _controller.value.duration.inSeconds.toDouble() > 0
                                        ? _controller.value.duration.inSeconds.toDouble()
                                        : 1.0,
                                    onChanged: (val) {
                                      _controller.seekTo(Duration(seconds: val.toInt()));
                                      _resetHideTimer();
                                    },
                                  ),
                                ),
                              ),
                              Text(
                                _fmt(_controller.value.duration),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                          // Bottom Classic MX Buttons Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left: Screen Lock Icon
                              IconButton(
                                icon: const Icon(Icons.lock_open_outlined, color: Colors.white, size: 24),
                                onPressed: () => setState(() => _isLocked = true),
                              ),
                              // Center: Previous | Play/Pause | Next
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 34),
                                    onPressed: () {
                                      _controller.seekTo(_controller.value.position - const Duration(seconds: 10));
                                    },
                                  ),
                                  const SizedBox(width: 24),
                                  IconButton(
                                    icon: Icon(
                                      _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 42,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _controller.value.isPlaying ? _controller.pause() : _controller.play();
                                      });
                                      _resetHideTimer();
                                    },
                                  ),
                                  const SizedBox(width: 24),
                                  IconButton(
                                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 34),
                                    onPressed: () {
                                      _controller.seekTo(_controller.value.position + const Duration(seconds: 10));
                                    },
                                  ),
                                ],
                              ),
                              // Right: Aspect Ratio / Crop Button
                              IconButton(
                                icon: const Icon(Icons.aspect_ratio_rounded, color: Colors.white, size: 24),
                                onPressed: () {
                                  setState(() => _aspectMode = (_aspectMode + 1) % 3);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
