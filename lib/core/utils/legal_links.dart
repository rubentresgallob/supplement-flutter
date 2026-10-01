import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/api_constants.dart';
import '../widgets/ui/ui.dart';

/// Páginas legales publicadas en el backend (las tiendas exigen una URL pública).
enum LegalPage {
  privacy('/privacidad.html'),
  terms('/terminos.html'),
  deleteAccount('/eliminar-cuenta.html');

  final String path;
  const LegalPage(this.path);

  Uri get uri => Uri.parse('${ApiConstants.baseUrl}$path');
}

/// Abre la página en el navegador del móvil.
Future<void> openLegalPage(BuildContext context, LegalPage page) async {
  final opened = await launchUrl(page.uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    AppToast.error(context, 'No se pudo abrir ${page.uri}');
  }
}
