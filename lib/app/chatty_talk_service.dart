import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ChattyTalkService {
  static const _modelName = 'SmolLM2-360M-Instruct-Q4_K_M.gguf';
  static const _modelAsset = 'assets/models/$_modelName';
  static const _channel = MethodChannel('chatty_pet/inference_bridge');
  static const _events = EventChannel('chatty_pet/inference_events');

  Stream<Map<Object?, Object?>> events() => _events
      .receiveBroadcastStream()
      .map((event) => Map<Object?, Object?>.from(event as Map));

  Future<String> prepareModel() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/chatty_pet/models');
    await directory.create(recursive: true);
    final destination = File('${directory.path}/$_modelName');
    final asset = await rootBundle.load(_modelAsset);
    if (!await destination.exists() ||
        await destination.length() != asset.lengthInBytes) {
      final temporary = File('${destination.path}.installing');
      if (await temporary.exists()) await temporary.delete();
      await temporary.writeAsBytes(
        asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
        flush: true,
      );
      if (await destination.exists()) await destination.delete();
      await temporary.rename(destination.path);
    }
    return destination.path;
  }

  Future<Map<Object?, Object?>> begin({
    required String modelPath,
    required String prompt,
  }) async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'startGeneration',
      {
        'prompt': prompt,
        'modelPath': modelPath,
        'contextSize': 1024,
        // Chatty is a quick back-and-forth companion, not a long-form
        // assistant. A short cap keeps the bundled mobile model responsive.
        'maxTokens': 40,
        'temperature': 0.55,
        'topP': 0.9,
        'topK': 40,
        'gpuLayers': 0,
      },
    );
    return result ?? const {};
  }

  Future<void> cancel(String requestId) =>
      _channel.invokeMethod<void>('cancelGeneration', {'requestId': requestId});
}
