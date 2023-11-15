import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:webview_windows/webview_windows.dart';
import 'package:window_manager/window_manager.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: DefaultTabController(
        length: 3, // Number of tabs
        child: ExampleBrowser(),
      ),
    );
  }
}

class ExampleBrowser extends StatefulWidget {
  @override
  State<ExampleBrowser> createState() => _ExampleBrowserState();
}

class _ExampleBrowserState extends State<ExampleBrowser> {
  final List<String> websites = [
    'https://www.chatgpt.com/',
    'https://bard.google.com/chat',
    'https://www.adobe.com/sensei/generative-ai/firefly.html',
  ];

  final List<WebviewController> controllers = List.generate(
      3, (index) => WebviewController()); // Create WebviewControllers

  int currentIndex = 0; // Current tab index

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    try {
      for (var i = 0; i < controllers.length; i++) {
        await controllers[i].initialize();
        await controllers[i].setBackgroundColor(Colors.transparent);
        await controllers[i]
            .setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
        await controllers[i].loadUrl(websites[i]);
      }

      if (!mounted) return;
      setState(() {});
    } on PlatformException catch (e) {
      // Error handling logic
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.black,
        bottom: TabBar(
          tabs: [
            Tab(text: 'ChatGPT'),
            Tab(text: 'Bard'),
            Tab(text: 'FireFly'),
          ],
          onTap: (index) {
            setState(() {
              currentIndex = index; // Update current tab index
            });
          },
        ),
      ),
      body: TabBarView(
        children: [
          buildWebView(0),
          buildWebView(1),
          buildWebView(2),
        ],
      ),
    );
  }

  Widget buildWebView(int index) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () {
                controllers[index].goBack();
              },
            ),
            IconButton(
              icon: Icon(
                Icons.arrow_forward,
                color: Colors.white,
              ),
              onPressed: () {
                controllers[index].goForward();
              },
            ),
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: Colors.white,
              ),
              onPressed: () {
                controllers[index].reload();
              },
            ),
          ],
        ),
        Expanded(
          child: Card(
            color: Colors.transparent,
            elevation: 0,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Stack(
              children: [
                Webview(
                  controllers[index],
                  permissionRequested: _onPermissionRequested,
                ),
                StreamBuilder<LoadingState>(
                  stream: controllers[index].loadingState,
                  builder: (context, snapshot) {
                    if (snapshot.hasData &&
                        snapshot.data == LoadingState.loading) {
                      return LinearProgressIndicator();
                    } else {
                      return SizedBox();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<WebviewPermissionDecision> _onPermissionRequested(
      String url, WebviewPermissionKind kind, bool isUserInitiated) async {
    final decision = await showDialog<WebviewPermissionDecision>(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('WebView permission requested'),
        content: Text('WebView has requested permission \'$kind\''),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.deny),
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.allow),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    return decision ?? WebviewPermissionDecision.none;
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
