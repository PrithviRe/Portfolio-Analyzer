import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'keys.dart';
import 'stockanalysispage.dart';

const String firebaseUrl =
    "https://stock-analysis-api-6ipcyfmu4a-uc.a.run.app"; // Backend URL

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;

  void _openWebView(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WebViewScreen(url: url)),
    ).then((requestToken) async {
      if (!mounted || requestToken == null) return;

      debugPrint("Captured Request Token: $requestToken");
      String accessToken = await getAccessToken(
        apiKey,
        apiSecret,
        requestToken,
      );
      debugPrint("Access Token: $accessToken");

      if (accessToken.isNotEmpty && mounted) {
        setState(() => _isLoading = true);

        try {
          final holdings = await getHoldings(apiKey, accessToken);
          final List<String> portfolio = [
            for (var stock in holdings["data"]) "${stock["tradingsymbol"]}.NS",
          ];

          final analysisData = await getAIAnalysis(portfolio);

          if (!mounted) return;

          setState(() => _isLoading = false);

          if (!mounted) return;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StockAnalysisPage(data: analysisData),
              ),
            );
          });
        } catch (e) {
          if (!mounted) return;

          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to get AI analysis')));
        }
      }
    });
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ElevatedButton(
                        onPressed: () => _openWebView(loginUrl),
                        style: ButtonStyle(
                          backgroundColor: const WidgetStatePropertyAll(
                            Colors.orange,
                          ),
                          shape: const WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                          ),
                          fixedSize: const WidgetStatePropertyAll(
                            Size(500, 60),
                          ),
                        ),
                        child: const Text(
                          'Login with Zerodha',
                          style: TextStyle(fontSize: 25),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => _launchURL(signUpUrl),
                      child: const Text('Sign up instead'),
                    ),
                  ],
                ),
              ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  final String url;
  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..clearCache() // clear cache to avoid ERR_CACHE_MISS
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (_) => setState(() => _isLoading = true),
              onPageFinished: (url) {
                setState(() => _isLoading = false);

                if (url.contains("request_token=")) {
                  Uri uri = Uri.parse(url);
                  String? requestToken = uri.queryParameters["request_token"];
                  if (requestToken != null) {
                    Navigator.pop(context, requestToken);
                  }
                }
              },
              onWebResourceError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error loading page: ${error.description}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Zerodha Login")),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

Future<String> getAccessToken(
  String apiKey,
  String apiSecret,
  String requestToken,
) async {
  final String url = "https://api.kite.trade/session/token";
  String checksum = generateChecksum(apiKey, requestToken, apiSecret);

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "X-Kite-Version": "3",
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "api_key": apiKey,
        "request_token": requestToken,
        "checksum": checksum,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["data"]["access_token"];
    } else {
      debugPrint("Error: ${response.body}");
      return "";
    }
  } catch (e) {
    debugPrint("Error: $e");
    return "";
  }
}

Future<Map<String, dynamic>> getHoldings(
  String apiKey,
  String accessToken,
) async {
  final String url = "https://api.kite.trade/portfolio/holdings";

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        "X-Kite-Version": "3",
        "Authorization": "token $apiKey:$accessToken",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint("Holdings: $data");
      return data;
    } else {
      debugPrint(
        "Failed to fetch holdings. Status code: ${response.statusCode}",
      );
      debugPrint("Response body: ${response.body}");
      return {};
    }
  } catch (e) {
    debugPrint("Error fetching holdings: $e");
    return {};
  }
}

Future<Map<String, dynamic>> getAIAnalysis(List<String> portfolio) async {
  final url = Uri.parse(firebaseUrl);
  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: json.encode({"stocks": portfolio}),
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> analysis = json.decode(response.body);
    debugPrint('AI Analysis: $analysis');
    return analysis;
  } else {
    throw Exception('Failed to get AI analysis');
  }
}

String generateChecksum(String apiKey, String requestToken, String apiSecret) {
  String input = "$apiKey$requestToken$apiSecret";
  return sha256.convert(utf8.encode(input)).toString();
}
