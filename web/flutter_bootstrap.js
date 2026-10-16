{{flutter_js}}
{{flutter_build_config}}

// Nada desde servidores de Google: CanvasKit va empaquetado (se compila con
// --no-web-resources-cdn) y las fuentes de respaldo (emojis, otros alfabetos)
// se buscan en nuestro propio alojamiento en vez de en fonts.gstatic.com.
// No las alojamos: si un texto lleva caracteres que Poppins no tiene, se ve un hueco.
_flutter.loader.load({
  config: {
    fontFallbackBaseUrl: "assets/fallback-fonts/",
  },
});
