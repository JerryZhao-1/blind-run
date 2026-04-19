import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/place_suggestion.dart';
import 'package:aidrun_demo/core/services/amap_config.dart';
import 'package:aidrun_demo/core/services/amap_location_service.dart';
import 'package:aidrun_demo/core/services/speech_recognition_service.dart';
import 'package:aidrun_demo/core/theme/app_theme.dart';
import 'package:aidrun_demo/core/widgets/blind_page_scaffold.dart';
import 'package:aidrun_demo/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BlindPlaceSearchPage extends ConsumerStatefulWidget {
  const BlindPlaceSearchPage({super.key});

  @override
  ConsumerState<BlindPlaceSearchPage> createState() =>
      _BlindPlaceSearchPageState();
}

class _BlindPlaceSearchPageState extends ConsumerState<BlindPlaceSearchPage> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _queryFocusNode = FocusNode();

  bool _loading = false;
  List<PlaceSuggestion> _results = const [];
  DeviceLocation? _currentLocation;
  bool _resolvedEffectiveConfig = false;
  bool _hasEffectiveWebKey = false;
  VoiceCaptureState _voiceState = VoiceCaptureState.idle;
  String _voiceMessage = '输入地点名称，或使用语音搜索地点。';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(blindAccessibilityServiceProvider)
          .announcePage('地点搜索页面。请输入地点名称，或使用语音搜索。搜索结果会读出地点和地址。');
      final location = await ref.read(appLocationServiceProvider).locateOnce();
      final effectiveConfig = await AMapConfig.load();
      if (!mounted) {
        return;
      }
      setState(() {
        _currentLocation = location;
        _resolvedEffectiveConfig = true;
        _hasEffectiveWebKey = effectiveConfig.hasWebKey;
      });
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _queryFocusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _voiceMessage = '请先输入地点名称，或使用语音搜索。';
      });
      await ref
          .read(blindAccessibilityServiceProvider)
          .announceError(_voiceMessage);
      return;
    }
    setState(() => _loading = true);
    final results = await ref
        .read(placeSearchServiceProvider)
        .search(query, near: _currentLocation);
    if (!mounted) {
      return;
    }
    final firstResult = results.isEmpty ? null : results.first;
    setState(() {
      _results = results;
      _loading = false;
      _voiceMessage = results.isEmpty
          ? '没有找到匹配地点，请尝试更换关键词。'
          : '已找到${results.length}个地点候选。第一条是${firstResult!.name}，${_addressReadout(firstResult)}。请逐项选择。';
    });
    await ref
        .read(blindAccessibilityServiceProvider)
        .announceStatusChange(_voiceMessage);
  }

  Future<void> _searchByVoice() async {
    await ref
        .read(blindAccessibilityServiceProvider)
        .announcePage('请直接说出想去的地点名称。');
    final result = await ref
        .read(speechRecognitionServiceProvider)
        .listenForTranscript(
          onStateChanged: (state) {
            if (!mounted) {
              return;
            }
            setState(() {
              _voiceState = state;
              _voiceMessage = switch (state) {
                VoiceCaptureState.idle => '输入地点名称，或使用语音搜索地点。',
                VoiceCaptureState.listening => '正在收听地点名称，请直接说出目的地。',
                VoiceCaptureState.processing => '正在处理语音内容，请稍候。',
                VoiceCaptureState.success => '语音识别成功，正在开始搜索。',
                VoiceCaptureState.error => '没有识别到清晰地点，请改用文字搜索或再次尝试语音。',
                VoiceCaptureState.unavailable => '当前设备语音搜索不可用，请使用文字搜索地点。',
              };
            });
          },
        );
    if (!mounted) {
      return;
    }
    if (result.state != VoiceCaptureState.success || !result.hasTranscript) {
      await ref
          .read(blindAccessibilityServiceProvider)
          .announceError(_voiceMessage);
      return;
    }
    _queryController.text = result.transcript;
    await _search();
  }

  String _addressReadout(PlaceSuggestion place) {
    return place.address.isEmpty ? '未提供详细地址' : place.address;
  }

  @override
  Widget build(BuildContext context) {
    final showMissingWebKeyWarning =
        _resolvedEffectiveConfig ? !_hasEffectiveWebKey : false;

    return BlindPageScaffold(
      aiButtonKey: const Key('blind-ai-assistant-button'),
      header: Row(
        children: [
          BlindAccessibleButton(
            onPressed: () => context.pop(),
            enabled: true,
            label: '返回预约页面',
            hint: '返回上一步继续填写预约',
            child: FilledButton.icon(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.zinc,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              icon: const Icon(Icons.arrow_back),
              label: const Text(
                '返回',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Semantics(
              header: true,
              child: const Text(
                '搜索地点',
                style: TextStyle(
                  color: AppTheme.yellow,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          if (showMissingWebKeyWarning) ...[
            Semantics(
              container: true,
              label: '当前未配置高德地点搜索 key，地点候选将回退为本地演示数据。',
              child: SectionCard(
                color: const Color(0xFF1F2937),
                child: Text(
                  '当前未配置高德 Web Service Key，地点候选将回退为本地演示数据。',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  textField: true,
                  label: '地点搜索输入框',
                  hint: '输入公园、小区或地标名称',
                  child: TextField(
                    controller: _queryController,
                    focusNode: _queryFocusNode,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      labelText: '地点关键词',
                      hintText: '例如朝阳公园',
                      suffixIcon: IconButton(
                        key: const Key('blind-place-search-submit-button'),
                        onPressed: _search,
                        icon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  container: true,
                  liveRegion: true,
                  focusable: false,
                  label: _voiceMessage,
                  child: ExcludeSemantics(
                    child: Text(
                      _voiceMessage,
                      style: const TextStyle(
                        color: AppTheme.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                BlindAccessibleButton(
                  key: const Key('blind-place-search-voice-button'),
                  onPressed: _searchByVoice,
                  enabled: true,
                  label: '语音搜索地点',
                  hint: '开始语音录入地点名称；如果失败，可继续使用文字搜索',
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.yellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      icon: Icon(
                        _voiceState == VoiceCaptureState.listening
                            ? Icons.graphic_eq
                            : Icons.mic,
                      ),
                      label: Text(
                        switch (_voiceState) {
                          VoiceCaptureState.listening => '正在收听地点...',
                          VoiceCaptureState.processing => '正在处理语音...',
                          _ => '语音搜索地点',
                        },
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_results.isEmpty)
            const SectionCard(
              color: AppTheme.zinc,
              child: Text(
                '还没有搜索结果。请输入关键词，或使用语音搜索。',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          else
            ..._results.map(
              (place) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BlindAccessibleButton(
                  onPressed: () => context.pop(place),
                  enabled: true,
                  label: '地点候选，${place.name}，地址${_addressReadout(place)}，选择此地点',
                  hint: '双击选择这个地点并返回预约页面',
                  child: SectionCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const ExcludeSemantics(
                        child: CircleAvatar(child: Icon(Icons.place)),
                      ),
                      title: Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          place.address.isEmpty ? '未提供详细地址' : place.address,
                        ),
                      ),
                      trailing: FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('选择'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
