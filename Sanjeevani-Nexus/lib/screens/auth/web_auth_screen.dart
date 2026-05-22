import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/auth_api_config.dart';

class WebAuthScreen extends StatefulWidget {
  const WebAuthScreen({super.key});

  @override
  State<WebAuthScreen> createState() => _WebAuthScreenState();
}

class _WebAuthScreenState extends State<WebAuthScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  static const String _callbackScheme = 'sanjeevani';
  static const String _callbackHost = 'nexus';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.darkGreen)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (_checkForToken(url)) {
              return;
            }
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            if (_checkForToken(url)) {
              return;
            }
          },
          onWebResourceError: (error) {
            setState(() {
              _errorMessage = 'Failed to load authentication page';
              _isLoading = false;
            });
          },
          onNavigationRequest: (request) {
            if (request.url.startsWith('$_callbackScheme://$_callbackHost')) {
              _handleCallback(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    _loadAuthPage();
  }

  void _loadAuthPage() {
    final authUrl =
        '${AuthApiConfig.baseUrl}/auth/google/login?app_id=${AuthApiConfig.appId}&requested_role=${AuthApiConfig.requestedRole}&redirect_type=mobile';
    _controller.loadRequest(Uri.parse(authUrl));
  }

  bool _checkForToken(String url) {
    try {
      final uri = Uri.parse(url);

      if (uri.host == 'nexus' && uri.scheme == _callbackScheme) {
        _handleCallback(url);
        return true;
      }

      final token = uri.queryParameters['token'];
      if (token != null) {
        _handleToken(token, url);
        return true;
      }

      if (url.contains('token=')) {
        final match = RegExp(r'token=([^&]+)').firstMatch(url);
        if (match != null) {
          _handleToken(match.group(1)!, url);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error parsing URL: $e');
    }
    return false;
  }

  Future<void> _handleCallback(String url) async {
    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse(url);
      String? token;

      token = uri.queryParameters['token'];

      if (token == null && url.contains('token=')) {
        final match = RegExp(r'token=([^&]+)').firstMatch(url);
        token = match?.group(1);
      }

      if (token != null) {
        await _handleToken(token, url);
      } else {
        _handleError('Authentication failed - no token received');
      }
    } catch (e) {
      _handleError('Failed to process authentication: $e');
    }
  }

  Future<void> _handleToken(String token, String url) async {
    try {
      final userData = await AuthService().fetchUserProfile(token);

      if (userData != null) {
        await AuthService().saveGoogleAuth(token, userData);

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _handleError('Failed to fetch user profile');
      }
    } catch (e) {
      _handleError('Authentication error: $e');
    }
  }

  void _handleError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.error,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkGreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sign in with Google',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: AppTheme.darkGreen.withOpacity(0.9),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.neonGreen,
                ),
              ),
            ),
          if (_errorMessage != null)
            Container(
              color: AppTheme.darkGreen.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.error,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _isLoading = true;
                        });
                        _loadAuthPage();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonGreen,
                        foregroundColor: AppTheme.darkGreen,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
