import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

const kHost = 'topikbotuz.vercel.app';
const kSite = 'https://$kHost';
const kBg = Color(0xFF0B0E15);
const kFileExt = ['.pdf', '.zip', '.rar', '.7z', '.docx', '.doc', '.xlsx', '.apk'];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: kBg,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: kBg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const TopikApp());
}

class TopikApp extends StatelessWidget {
  const TopikApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'TOPIK 한국',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true)
            .copyWith(scaffoldBackgroundColor: kBg),
        home: const WebPage(),
      );
}

class WebPage extends StatefulWidget {
  const WebPage({super.key});
  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  late final WebViewController _c;
  int _progress = 0;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(kBg)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => setState(() => _progress = p),
        onPageStarted: (_) => setState(() => _error = false),
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? false) setState(() => _error = true);
        },
        onNavigationRequest: (req) {
          final uri = Uri.parse(req.url);
          final isFile =
              kFileExt.any((x) => uri.path.toLowerCase().endsWith(x));
          final isSite = uri.host == kHost;
          if (!isSite || isFile) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(kSite));

    final platform = _c.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _c.canGoBack()) {
          _c.goBack();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(children: [
            WebViewWidget(controller: _c),
            if (_progress < 100 && !_error)
              LinearProgressIndicator(value: _progress / 100, minHeight: 3),
            if (_error)
              Container(
                color: kBg,
                alignment: Alignment.center,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.wifi_off, size: 64),
                  const SizedBox(height: 12),
                  const Text('Internet aloqasi yo‘q'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      setState(() => _error = false);
                      _c.loadRequest(Uri.parse(kSite));
                    },
                    child: const Text('Qayta urinish'),
                  ),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}
