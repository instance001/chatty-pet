package io.instance001.chattypet

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val inferenceChannel = "chatty_pet/inference_bridge"
    private val inferenceEventsChannel = "chatty_pet/inference_events"
    // Loading the native runtime is deliberately deferred until a child opens
    // Talk to Chatty. The care toy should start exactly as it did before chat
    // was added, without allocating native inference resources at launch.
    private val inferenceBridge by lazy { InferenceBridge() }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            inferenceChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadModel" -> {
                    val modelPath = call.argument<String>("modelPath")
                    val contextSize = call.argument<Int>("contextSize") ?: 1024
                    val gpuLayers = call.argument<Int>("gpuLayers") ?: 0
                    if (modelPath == null) {
                        result.error("missing_model_path", "modelPath is required", null)
                    } else {
                        result.success(inferenceBridge.loadModel(modelPath, contextSize, gpuLayers))
                    }
                }
                "startGeneration" -> {
                    val prompt = call.argument<String>("prompt")
                    val modelPath = call.argument<String>("modelPath")
                    val contextSize = call.argument<Int>("contextSize") ?: 1024
                    val maxTokens = call.argument<Int>("maxTokens") ?: 72
                    val temperature = call.argument<Double>("temperature") ?: 0.55
                    val topP = call.argument<Double>("topP") ?: 0.9
                    val topK = call.argument<Int>("topK") ?: 40
                    val gpuLayers = call.argument<Int>("gpuLayers") ?: 0
                    if (prompt == null || modelPath == null) {
                        result.error("missing_generation_args", "prompt and modelPath are required", null)
                    } else {
                        result.success(
                            inferenceBridge.startGeneration(
                                prompt,
                                modelPath,
                                contextSize,
                                maxTokens,
                                temperature,
                                topP,
                                topK,
                                gpuLayers
                            )
                        )
                    }
                }
                "cancelGeneration" -> {
                    val requestId = call.argument<String>("requestId")
                    if (requestId == null) {
                        result.error("missing_request_id", "requestId is required", null)
                    } else {
                        inferenceBridge.cancelGeneration(requestId)
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            inferenceEventsChannel
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                inferenceBridge.attachSink(events)
            }

            override fun onCancel(arguments: Any?) {
                inferenceBridge.attachSink(null)
            }
        })
    }
}
