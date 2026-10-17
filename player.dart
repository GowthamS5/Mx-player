import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MxApp());
}

class MxApp extends StatelessWidget {
  const MxApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MX Player Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0057D9), elevation: 2),
      ),
      home: const MxHome(),
    );
  }
}

class VItem {
  final String title, path, folder, size, tag;
  final bool isNew;
  VItem(this.title, this.path, this.folder, this.size, {this.tag = '1080p', this.isNew = true});
}

class MxHome extends StatefulWidget {
  const MxHome({super.key});
  @override
  State<MxHome> createState() => _MxHomeState();
}

class _MxHomeState extends State<MxHome> {
  bool _grid = false, _dark = true;
  String? _curFolder;

  final List<VItem> _videos = [
    VItem('Big_Buck_Bunny_1080p.mp4', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4', 'Movies', '158 MB'),
    VItem('Sintel_4K_Dolby.mkv', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4', 'Movies', '412 MB', tag: '4K', isNew: false),
    VItem('For_Bigger_Blazes.mp4', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4', 'WhatsApp Video', '14 MB', tag: '720p'),
    VItem('Elephants_Dream.mp4', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4', 'Download', '84 MB'),
  ];

  Map<String, List<VItem>> get _folders {
    final map = <String, List<VItem>>{};
    for (var v in _videos) {
      map.putIfAbsent(v.folder, () => []).add(v);
    }
    return map;
  }

  void _streamDialog() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Play Network Video (URL)'),
        content: TextField(controller: c, decoration: const InputDecoration(hintText: 'https://example.com/video.mp4')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (c.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                _openPlayer(VItem('Network Stream', c.text.trim(), 'Stream', 'LIVE'));
              }
            },
            child: const Text('PLAY'),
          ),
        ],
      ),
    );
  }

  void _openPlayer(VItem v) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => MxPlayerScreen(video: v)));
  }

  @override
  Widget build(BuildContext context) {
    final bg = _dark ? const Color(0xFF121212) : const Color(0xFFF5F6F8);
    final card = _dark ? const Color(0xFF1E1E1E) : Colors.white;
    final txt = _dark ? Colors.white : Colors.black87;
    final sub = _dark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: _curFolder != null
            ? IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => setState(() => _curFolder = null))
            : null,
        title: _curFolder != null
            ? Text(_curFolder!, style: const TextStyle(color: Colors.white, fontSize: 18))
            : Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                  child: const Row(children: [
                    Icon(Icons.play_arrow, color: Color(0xFF0057D9), size: 16),
                    Text('MX', style: TextStyle(color: Color(0xFF0057D9), fontWeight: FontWeight.w900, fontSize: 14)),
                  ]),
                ),
                const SizedBox(width: 8),
                const Text('Player', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ]),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: _streamDialog, tooltip: 'Search URL'),
          IconButton(icon: Icon(_grid ? Icons.view_list : Icons.grid_view, color: Colors.white), onPressed: () => setState(() => _grid = !_grid)),
          IconButton(icon: const Icon(Icons.cloud_queue, color: Colors.white), onPressed: _streamDialog, tooltip: 'Network Stream'),
          IconButton(icon: const Icon(Icons.brightness_6, color: Colors.white), onPressed: () => setState(() => _dark = !_dark)),
        ],
      ),
      body: _curFolder == null ? _buildFolders(txt, sub, card) : _buildVideos(_folders[_curFolder!] ?? [], txt, sub),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0057D9),
        onPressed: _streamDialog,
        child: const Icon(Icons.add, color: Colors.white, size: 34),
        tooltip: 'Add Network Video',
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: card,
        selectedItemColor: const Color(0xFF0057D9),
        unselectedItemColor: sub,
        onTap: (i) {
          if (i == 0) setState(() => _curFolder = null);
          if (i == 1) _streamDialog();
          if (i == 2) _streamDialog();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Folders'),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle), label: 'Stream'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud_queue), label: 'Network'),
        ],
      ),
    );
  }

  Widget _buildFolders(Color txt, Color sub, Color card) {
    final list = _folders.entries.toList();
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: card,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Folders (${list.length})', style: TextStyle(color: sub, fontWeight: FontWeight.bold, fontSize: 13)),
          const Text('Ad-Free MX UI', style: TextStyle(color: Color(0xFF0057D9), fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      ),
      Expanded(
        child: _grid
            ? GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                itemCount: list.length,
                itemBuilder: (_, i) => InkWell(
                  onTap: () => setState(() => _curFolder = list[i].key),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.folder_rounded, color: Color(0xFFFFB703), size: 64),
                    Text('${list[i].key} (${list[i].value.length})', maxLines: 1, style: TextStyle(color: txt, fontSize: 12)),
                  ]),
                ),
              )
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, color: Colors.white10),
                itemBuilder: (_, i) {
                  final e = list[i];
                  return ListTile(
                    leading: const Icon(Icons.folder_rounded, color: Color(0xFF4285F4), size: 46),
                    title: Row(children: [
                      Expanded(child: Text(e.key, style: TextStyle(color: txt, fontWeight: FontWeight.w600))),
                      if (e.value.any((v) => v.isNew))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(3)),
                          child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                    ]),
                    subtitle: Text('${e.value.length} videos', style: TextStyle(color: sub, fontSize: 12)),
                    onTap: () => setState(() => _curFolder = e.key),
                  );
                },
              ),
      ),
    ]);
  }

  Widget _buildVideos(List<VItem> vids, Color txt, Color sub) {
    return ListView.separated(
      itemCount: vids.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 110, color: Colors.white10),
      itemBuilder: (_, i) {
        final v = vids[i];
        return ListTile(
          onTap: () => _openPlayer(v),
          leading: Container(
            width: 88,
            height: 52,
            decoration: BoxDecoration(color: const Color(0xFF1F2B3E), borderRadius: BorderRadius.circular(5)),
            child: Stack(children: [
              const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70)),
              Positioned(
                right: 4,
                bottom: 2,
                child: Text(v.tag, style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
          title: Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: txt, fontSize: 14)),
          subtitle: Text(v.size, style: TextStyle(color: sub, fontSize: 12)),
        );
      },
    );
  }
}

class MxPlayerScreen extends StatefulWidget {
  final VItem video;
  const MxPlayerScreen({super.key, required this.video});
  @override
  State<MxPlayerScreen> createState() => _MxPlayerScreenState();
}

class _MxPlayerScreenState extends State<MxPlayerScreen> {
  late VideoPlayerController _ctrl;
  bool _ready = false, _hud = true, _lock = false, _hwPlus = true, _land = true, _hold2x = false;
  double _bright = 0.85, _vol = 0.85, _spd = 1.0;
  int _fit = 0;
  String? _hudMsg;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setOrient(true);
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.video.path));
    _ctrl.initialize().then((_) {
      _ctrl.play();
      _ctrl.addListener(() {
        if (mounted) setState(() {});
      });
      setState(() => _ready = true);
      _autoHide();
    });
  }

  void _setOrient(bool l) {
    _land = l;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(l ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight] : [DeviceOrientation.portraitUp]);
  }

  void _autoHide() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted && _ctrl.value.isPlaying) setState(() => _hud = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  String _fmt(Duration d) => '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final boxFit = _fit == 1 ? BoxFit.cover : (_fit == 2 ? BoxFit.fill : BoxFit.contain);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() => _hud = !_hud);
          if (_hud) _autoHide();
        },
        onDoubleTap: () => !_lock && _ready ? setState(() => _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play()) : null,
        onLongPressStart: (_) {
          if (!_lock && _ready) {
            _ctrl.setPlaybackSpeed(2.0);
            setState(() => _hold2x = true);
          }
        },
        onLongPressEnd: (_) {
          if (!_lock && _ready) {
            _ctrl.setPlaybackSpeed(_spd);
            setState(() => _hold2x = false);
          }
        },
        onVerticalDragUpdate: (d) {
          if (_lock) return;
          final delta = -d.primaryDelta! / 200;
          setState(() {
            if (d.globalPosition.dx < w / 2) {
              _bright = (_bright + delta).clamp(0.1, 1.0);
              _hudMsg = 'Brightness: ${(_bright * 15).round()} / 15';
            } else {
              _vol = (_vol + delta).clamp(0.0, 1.0);
              _ctrl.setVolume(_vol);
              _hudMsg = 'Volume: ${(_vol * 15).round()} / 15';
            }
          });
        },
        onVerticalDragEnd: (_) => setState(() => _hudMsg = null),
        onHorizontalDragUpdate: (d) {
          if (_lock || !_ready) return;
          final sec = (d.primaryDelta! * 0.4).round();
          _ctrl.seekTo(_ctrl.value.position + Duration(seconds: sec));
          setState(() => _hudMsg = '[ ${_fmt(_ctrl.value.position)} ]');
        },
        onHorizontalDragEnd: (_) => setState(() => _hudMsg = null),
        child: Stack(fit: StackFit.expand, children: [
          if (_ready)
            Center(
              child: SizedBox.expand(
                child: FittedBox(
                  fit: boxFit,
                  child: SizedBox(width: _ctrl.value.size.width, height: _ctrl.value.size.height, child: VideoPlayer(_ctrl)),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Color(0xFF0057D9))),
          IgnorePointer(child: Container(color: Colors.black.withOpacity((1.0 - _bright) * 0.8))),
          if (_hudMsg != null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                child: Text(_hudMsg!, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
          if (_hold2x)
            const Positioned(top: 24, left: 0, right: 0, child: Center(child: Chip(label: Text('2.0x Fast Play >>')))),
          if (_hud && _lock)
            Positioned(
              top: 24,
              left: 24,
              child: IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.black87),
                icon: const Icon(Icons.lock, color: Color(0xFF0078FF), size: 28),
                onPressed: () => setState(() => _lock = false),
              ),
            ),
          if (_hud && !_lock && _ready)
            Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                color: Colors.black54,
                child: SafeArea(
                  bottom: false,
                  child: Row(children: [
                    IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                    Expanded(child: Text(widget.video.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    TextButton(
                      onPressed: () => setState(() => _hwPlus = !_hwPlus),
                      child: Text(_hwPlus ? 'HW+' : 'SW', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () {
                        final s = [0.5, 1.0, 1.25, 1.5, 2.0];
                        _spd = s[(s.indexOf(_spd) + 1) % s.length];
                        _ctrl.setPlaybackSpeed(_spd);
                        setState(() {});
                      },
                      child: Text('${_spd}x', style: const TextStyle(color: Colors.amber)),
                    ),
                    IconButton(icon: const Icon(Icons.music_note), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.subtitles), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.screen_rotation), onPressed: () => _setOrient(!_land)),
                  ]),
                ),
              ),
              Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: SafeArea(
                  top: false,
                  child: Column(children: [
                    Row(children: [
                      Text(_fmt(_ctrl.value.position), style: const TextStyle(fontSize: 12)),
                      Expanded(
                        child: Slider(
                          activeColor: const Color(0xFF0078FF),
                          value: _ctrl.value.position.inSeconds.toDouble().clamp(0, _ctrl.value.duration.inSeconds.toDouble()),
                          max: _ctrl.value.duration.inSeconds.toDouble() > 0 ? _ctrl.value.duration.inSeconds.toDouble() : 1.0,
                          onChanged: (v) => _ctrl.seekTo(Duration(seconds: v.toInt())),
                        ),
                      ),
                      Text(_fmt(_ctrl.value.duration), style: const TextStyle(fontSize: 12)),
                    ]),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      IconButton(icon: const Icon(Icons.lock_open), onPressed: () => setState(() => _lock = true)),
                      Row(children: [
                        IconButton(icon: const Icon(Icons.skip_previous, size: 32), onPressed: () => _ctrl.seekTo(_ctrl.value.position - const Duration(seconds: 10))),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: Icon(_ctrl.value.isPlaying ? Icons.pause : Icons.play_arrow, size: 40),
                          onPressed: () => setState(() => _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play()),
                        ),
                        const SizedBox(width: 20),
                        IconButton(icon: const Icon(Icons.skip_next, size: 32), onPressed: () => _ctrl.seekTo(_ctrl.value.position + const Duration(seconds: 10)),
                        ),
                      ]),
                      IconButton(icon: const Icon(Icons.aspect_ratio), onPressed: () => setState(() => _fit = (_fit + 1) % 3)),
                    ]),
                  ]),
                ),
              ),
            ]),
        ]),
      ),
    );
  }
}
