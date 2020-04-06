import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef void UnityWidgetCreatedCallback(UnityWidgetController controller);

class UnityWidgetController {
  final _UnityWidgetState _unityWidgetState;
  final MethodChannel channel;

  UnityWidgetController._(
      this.channel,
      this._unityWidgetState,
      ) {
    channel.setMethodCallHandler(_handleMethod);
  }

  static UnityWidgetController init(int id, _UnityWidgetState unityWidgetState) {
    final MethodChannel channel = MethodChannel('unity_view_$id');
    return UnityWidgetController._(
      channel, unityWidgetState,
    );
  }

  /// Returns true if Unity is ready and false otherwise.
  Future<bool> isReady() => channel.invokeMethod('isReady');

  /// Returns true once Unity is ready.
  Future<bool> createUnity() => channel.invokeMethod('createUnity');

  Future<bool> postMessage(String gameObject, methodName, message) => channel.invokeMethod('postMessage', <String, dynamic>{
      'gameObject': gameObject,
      'methodName': methodName,
      'message': message,
    });

  /// Unless an error is thrown, always returns true.
  Future<bool> pause() {
    print('Pressed paused');
    return channel.invokeMethod('pause');
  }

  /// Unless an error is thrown, always returns true.
  Future<bool> resume() => channel.invokeMethod('resume');

  /// Called from [UnityWidget.dispose]
  Future<void> _dispose() async {
    // await channel.invokeMethod('dispose');
  }

  /// Handles a method call from Android (on behalf of Unity) to Flutter.
  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case "onUnityMessage":
        if (_unityWidgetState.widget != null) {
          _unityWidgetState.widget.onUnityMessage(this, call.arguments);
        }
        break;
      default:
        throw UnimplementedError("Unimplemented ${call.method} method");
    }
  }
}

typedef onUnityMessageCallback = void Function(
    UnityWidgetController controller, dynamic handler);

class UnityWidget extends StatefulWidget {
  final UnityWidgetCreatedCallback onUnityViewCreated;

  ///Event fires when the [UnityWidget] gets a message from unity.
  final onUnityMessageCallback onUnityMessage;

  final bool isARScene;

  UnityWidget(
      {Key key, @required this.onUnityViewCreated, this.onUnityMessage, this.isARScene = false});

  @override
  _UnityWidgetState createState() => _UnityWidgetState();
}

class _UnityWidgetState extends State<UnityWidget> {
  UnityWidgetController _controller;

  @override
  void initState() {
    // widget.controller =

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    if (_controller != null) {
      _controller._dispose();
      _controller = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> creationParams = <String, dynamic>{
      'ar': widget.isARScene,
    };
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'unity_view',
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParamsCodec: const StandardMessageCodec(),
        creationParams: creationParams,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'unity_view',
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return new Text(
        '$defaultTargetPlatform is not yet supported by this plugin');
  }

  @override
  void didUpdateWidget(UnityWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void _onPlatformViewCreated(int id) {
    _controller = UnityWidgetController.init(id, this);
    
    print('--------------------------------------------');
    print('|          Internal setup complete          ');
    print('--------------------------------------------');

    if (widget.onUnityViewCreated != null) {
      widget.onUnityViewCreated(_controller);
    }
  }
}
