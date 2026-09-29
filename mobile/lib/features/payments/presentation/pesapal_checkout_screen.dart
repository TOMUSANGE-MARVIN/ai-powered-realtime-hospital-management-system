import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../data/payment_repository.dart';

/// Hosts Pesapal's checkout page (card + mobile money) in a WebView.
///
/// Pops with `true` once Pesapal redirects to our callback URL (payment
/// attempted), or `false` if the patient closes the page first. Either way
/// the caller asks the backend for the real status — the redirect itself
/// doesn't prove the payment succeeded.
class PesapalCheckoutScreen extends StatefulWidget {
  const PesapalCheckoutScreen({super.key, required this.checkoutUrl});

  final String checkoutUrl;

  @override
  State<PesapalCheckoutScreen> createState() => _PesapalCheckoutScreenState();
}

class _PesapalCheckoutScreenState extends State<PesapalCheckoutScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onNavigationRequest: (request) {
            if (request.url.contains(PaymentRepository.callbackPath)) {
              _finish(true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url != null && url.contains(PaymentRepository.callbackPath)) _finish(true);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              setState(() => _error = "Couldn't load the payment page. Check your connection.");
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _finish(bool attempted) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pop(attempted);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish(false);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => _finish(false),
          ),
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 18, color: seedTeal),
              SizedBox(width: 6),
              Text('Secure payment', style: TextStyle(fontSize: 17)),
            ],
          ),
          centerTitle: true,
          bottom: _progress < 100
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    minHeight: 2,
                    color: seedTeal,
                    backgroundColor: Colors.transparent,
                  ),
                )
              : null,
        ),
        body: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() => _error = null);
                          _controller.reload();
                        },
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              )
            : WebViewWidget(controller: _controller),
      ),
    );
  }
}
