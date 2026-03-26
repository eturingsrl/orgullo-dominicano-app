import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:video_player/video_player.dart';
import 'config/contact_config.dart';
import 'dart:async';

// Modelo para gestión de estado
class AppState extends ChangeNotifier {
  bool _isConnected = true;
  bool _isLoading = true;
  String _currentUrl = 'https://orgullodominicano.org/';
  bool _adsInitialized = false;
  
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String get currentUrl => _currentUrl;
  bool get adsInitialized => _adsInitialized;
  
  void setConnected(bool connected) {
    _isConnected = connected;
    notifyListeners();
  }
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void setCurrentUrl(String url) {
    _currentUrl = url;
    notifyListeners();
  }
  
  void setAdsInitialized(bool initialized) {
    _adsInitialized = initialized;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Google Mobile Ads de manera segura
  try {
    await MobileAds.instance.initialize();
    debugPrint('✅ Google Mobile Ads inicializado correctamente');
  } catch (e) {
    debugPrint('⚠️ Error al inicializar Google Mobile Ads: $e');
    // La app continúa funcionando sin anuncios
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orgullo Dominicano',
      theme: ThemeData(
        primarySwatch: Colors.red,
        primaryColor: const Color(0xFFCE1126), // Color de la bandera dominicana
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFCE1126),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _gradientAnimation;
  late Animation<double> _rotationAnimation;
  VideoPlayerController? _videoPlayerController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // Configurar animaciones principales
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // Controller para animación de fondo continua
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    // Animación para el gradiente de fondo
    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Animación de rotación sutil
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.linear,
      ),
    );
    
    // Inicializar video de fondo
    _initializeVideo();
    
    // Iniciar animaciones
    _animationController.forward();
    _backgroundController.repeat(); // Repetir indefinidamente
    
    // Navegar a la pantalla principal después de 5 segundos
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WebViewScreen()),
        );
      }
    });
  }

  Future<void> _initializeVideo() async {
    try {
      debugPrint('🎬 Iniciando carga del video...');
      
      // Verificar si el asset existe
      final assetPath = 'assets/videosplash.mp4';
      debugPrint('🎬 Intentando cargar video desde: $assetPath');
      
      _videoPlayerController = VideoPlayerController.asset(assetPath);
      
      debugPrint('🎬 Inicializando video player...');
      await _videoPlayerController!.initialize();
      
      // Verificar si el video se inicializó correctamente
      if (_videoPlayerController!.value.isInitialized) {
        debugPrint('🎬 Video inicializado correctamente');
        debugPrint('🎬 Duración del video: ${_videoPlayerController!.value.duration}');
        debugPrint('🎬 Tamaño del video: ${_videoPlayerController!.value.size}');
        
        await _videoPlayerController!.setLooping(true);
        await _videoPlayerController!.play();
        
        if (mounted) {
          setState(() {
            _videoInitialized = true;
          });
          debugPrint('✅ Video de fondo cargado exitosamente');
        }
      } else {
        debugPrint('❌ Video no se pudo inicializar');
        throw Exception('Video no se pudo inicializar');
      }
    } catch (e) {
      debugPrint('❌ Error inicializando video: $e');
      debugPrint('⚠️ Continuando sin video de fondo');
      // Continuar sin video si hay error
      if (mounted) {
        setState(() {
          _videoInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _backgroundController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCE1126),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video de fondo
          if (_videoInitialized && _videoPlayerController != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoPlayerController!.value.size.width,
                height: _videoPlayerController!.value.size.height,
                child: VideoPlayer(_videoPlayerController!),
              ),
            )
          else
            // Fallback atractivo con gradiente animado patriótico
            AnimatedBuilder(
              animation: _gradientAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [
                        0.0,
                        0.25 + (_gradientAnimation.value * 0.1),
                        0.5 + (_gradientAnimation.value * 0.2),
                        0.75 + (_gradientAnimation.value * 0.1),
                        1.0,
                      ],
                      colors: [
                        const Color(0xFFCE1126), // Rojo dominicano
                        const Color(0xFFFF6B85), // Rojo claro
                        const Color(0xFFFFFFFF), // Blanco
                        const Color(0xFF4A90E2), // Azul claro
                        const Color(0xFF002D62), // Azul dominicano
                      ],
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(
                          -0.5 + (_gradientAnimation.value * 1.0),
                          -0.5 + (_gradientAnimation.value * 1.0),
                        ),
                        radius: 1.0 + (_gradientAnimation.value * 0.5),
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          
          // Overlay semi-transparente para mejorar legibilidad
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          
          // Contenido principal
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo principal (bandera)
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/JvomKnnYTSKQZP1NvGZT_do.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Logo de "Orgullo Dominicano"
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Image.asset(
                        'assets/Transparente-no-liezo.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Texto descriptivo
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'Orgullo Dominicano: Donde la verdad y la patria se encuentran.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Loading indicator
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
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

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _controller;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _initWebView();
    
    // Monitoreo de conectividad
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (mounted) {
        Provider.of<AppState>(context, listen: false)
            .setConnected(result != ConnectivityResult.none);
      }
    });
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100 && mounted) {
              Provider.of<AppState>(context, listen: false).setLoading(false);
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              Provider.of<AppState>(context, listen: false).setLoading(true);
              Provider.of<AppState>(context, listen: false).setCurrentUrl(url);
              _updateNavigationButtons();
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              Provider.of<AppState>(context, listen: false).setLoading(false);
              _updateNavigationButtons();
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            // Permitir navegación dentro del dominio principal
            if (request.url.contains('orgullodominicano.org') ||
                request.url.startsWith('https://www.google.com') ||
                request.url.startsWith('https://www.facebook.com') ||
                request.url.startsWith('https://www.twitter.com') ||
                request.url.startsWith('https://www.instagram.com')) {
              return NavigationDecision.navigate;
            }
            
            // Bloquear URLs de ads/tracking para que no abran Safari
            if (request.url.contains('googlesyndication.com') ||
                request.url.contains('googleads.') ||
                request.url.contains('doubleclick.net') ||
                request.url.contains('google-analytics.com') ||
                request.url.contains('googletagmanager.com') ||
                request.url.contains('adservice.google.')) {
              return NavigationDecision.prevent;
            }
            
            // Abrir enlaces externos en el navegador
            _launchExternalUrl(request.url);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://orgullodominicano.org/'));
  }

  Future<void> _checkConnectivity() async {
    final ConnectivityResult connectivityResult =
        await Connectivity().checkConnectivity();
    if (mounted) {
      Provider.of<AppState>(context, listen: false)
          .setConnected(connectivityResult != ConnectivityResult.none);
    }
  }

  Future<void> _updateNavigationButtons() async {
    final canGoBack = await _controller.canGoBack();
    final canGoForward = await _controller.canGoForward();
    if (mounted) {
      setState(() {
        _canGoBack = canGoBack;
        _canGoForward = canGoForward;
      });
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _refreshPage() async {
    await _controller.reload();
  }

  Future<void> _sharePage() async {
    if (mounted) {
      final url = Provider.of<AppState>(context, listen: false).currentUrl;
      await Share.share(
        'Mira esta noticia en Orgullo Dominicano: $url',
        subject: 'Orgullo Dominicano - Noticias RD',
      );
    }
  }

  void _showContactSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contáctanos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (ContactConfig.websiteUrl.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Sitio web'),
                    subtitle: Text(ContactConfig.websiteUrl),
                    onTap: () {
                      Navigator.pop(context);
                      _launchExternalUrl(ContactConfig.websiteUrl);
                    },
                  ),
                if (ContactConfig.emailAddress.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Correo electrónico'),
                    subtitle: Text(ContactConfig.emailAddress),
                    onTap: () async {
                      final uri = Uri(
                        scheme: 'mailto',
                        path: ContactConfig.emailAddress,
                      );
                      Navigator.pop(context);
                      await launchUrl(uri);
                    },
                  ),
                if (ContactConfig.phoneNumber.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Teléfono'),
                    subtitle: Text(ContactConfig.phoneNumber),
                    onTap: () async {
                      final uri = Uri(
                        scheme: 'tel',
                        path: ContactConfig.phoneNumber,
                      );
                      Navigator.pop(context);
                      await launchUrl(uri);
                    },
                  ),
                if (ContactConfig.privacyPolicyUrl.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('Política de privacidad'),
                    subtitle: Text(ContactConfig.privacyPolicyUrl),
                    onTap: () {
                      Navigator.pop(context);
                      _launchExternalUrl(ContactConfig.privacyPolicyUrl);
                    },
                  ),
                if (ContactConfig.editorialGuidelinesUrl.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.rule),
                    title: const Text('Lineamientos editoriales y ética'),
                    subtitle: Text(ContactConfig.editorialGuidelinesUrl),
                    onTap: () {
                      Navigator.pop(context);
                      _launchExternalUrl(ContactConfig.editorialGuidelinesUrl);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_canGoBack,
      onPopInvoked: (didPop) {
        if (!didPop && _canGoBack) {
          _controller.goBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Orgullo Dominicano'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshPage,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _sharePage,
            ),
            PopupMenuButton<String>(
              onSelected: (String value) {
                switch (value) {
                  case 'home':
                    _controller.loadRequest(Uri.parse('https://orgullodominicano.org/'));
                    break;
                  case 'external':
                    _launchExternalUrl('https://orgullodominicano.org/');
                    break;
                  case 'contact':
                    _showContactSheet();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'home',
                  child: Row(
                    children: [
                      Icon(Icons.home, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      const Text('Inicio'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'external',
                  child: Row(
                    children: [
                      Icon(Icons.open_in_browser, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      const Text('Abrir en navegador'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'contact',
                  child: Row(
                    children: [
                      Icon(Icons.contact_mail, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      const Text('Contáctanos'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: Consumer<AppState>(
              builder: (context, appState, child) {
                return appState.isLoading
                    ? const LinearProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        backgroundColor: Colors.white24,
                      )
                    : Container(height: 4.0);
              },
            ),
          ),
        ),
        body: Consumer<AppState>(
          builder: (context, appState, child) {
            if (!appState.isConnected) {
              return _buildNoConnectionScreen();
            }
            
            return Column(
              children: [
                Expanded(
                  child: WebViewWidget(controller: _controller),
                ),
                _buildNavigationBar(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoConnectionScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'Sin conexión a internet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Verifica tu conexión e intenta de nuevo',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              _checkConnectivity();
              if (Provider.of<AppState>(context, listen: false).isConnected) {
                _refreshPage();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCE1126),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: _canGoBack ? const Color(0xFFCE1126) : Colors.grey,
            ),
            onPressed: _canGoBack ? () => _controller.goBack() : null,
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward,
              color: _canGoForward ? const Color(0xFFCE1126) : Colors.grey,
            ),
            onPressed: _canGoForward ? () => _controller.goForward() : null,
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Color(0xFFCE1126)),
            onPressed: () => _controller.loadRequest(
              Uri.parse('https://orgullodominicano.org/'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFCE1126)),
            onPressed: _refreshPage,
          ),
        ],
      ),
    );
  }
}
