import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Número en formato internacional SIN + ni espacios.
/// Ecuador: 593 + número. Ejemplo: 593989999999
const String whatsappNumberIntl = '593995650089'; // <- cámbialo por el real

String _waUrlFor(String product) {
  final msg = Uri.encodeComponent('Hola, quiero comprar: $product');
  return 'https://wa.me/$whatsappNumberIntl?text=$msg';
}

Future<void> openWhatsAppForProduct(BuildContext context, String product) async {
  final url = Uri.parse(_waUrlFor(product));
  final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
    );
  }
}

Future<void> showPurchaseDialog(BuildContext context, String product) {
  final phonePretty = '+${whatsappNumberIntl.substring(0,3)} '
      '${whatsappNumberIntl.substring(3)}';
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Compra por WhatsApp'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estamos trabajando para que puedas comprar online.\n'
            'Por el momento, realiza tu pedido por WhatsApp:',
          ),
          const SizedBox(height: 12),
          SelectableText('WhatsApp: $phonePretty'),
          const SizedBox(height: 8),
          Text('Producto: $product',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: '+$phonePretty'));
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Número copiado al portapapeles')),
              );
            }
          },
          child: const Text('Copiar número'),
        ),
        FilledButton(
          onPressed: () => openWhatsAppForProduct(context, product),
          child: const Text('Abrir WhatsApp'),
        ),
      ],
    ),
  );
}
