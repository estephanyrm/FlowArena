# ============================================
# Módulos auxiliares para vistas
# Contienen métodos reutilizables
# ============================================
module ApplicationHelper
  def inline_svg(path, options = {})
    file = Rails.root.join("app/assets/images", path)
    svg = File.read(file)
    content_tag(:div, raw(svg), options)
  end

  # Renderiza una imagen de evento de forma segura.
  #
  # Propshaft lanza Propshaft::MissingAssetError si el nombre del asset
  # no existe en app/assets/images. Esto sucede cuando:
  #   - Los tests de carga guardan nombres ficticios ("img.jpg", "prueba.jpg")
  #   - El archivo fue borrado pero su nombre sigue en la BD
  #
  # Estrategia:
  #   - URL externa (http/https) → <img src> directo, sin pasar por Propshaft
  #   - Asset local            → intentar resolver; si falla, usar fallback
  #   - Vacío / nil            → usar fallback directamente
  EVENTO_FALLBACK_PATH = "/assets/evento_default.jpg".freeze

  def evento_imagen_tag(src, html_options = {})
    html_options = html_options.dup

    img_src = if src.blank?
      EVENTO_FALLBACK_PATH
    elsif src.start_with?("http://", "https://", "//")
      # URL externa: no involucrar Propshaft
      src
    else
      # Asset local: resolverlo con Propshaft; caer al fallback si no existe
      begin
        asset_path(src)
      rescue Propshaft::MissingAssetError
        EVENTO_FALLBACK_PATH
      end
    end

    # Para imágenes externas o fallback también poner onerror por si acaso
    html_options[:onerror] ||= "this.onerror=null;this.src='#{EVENTO_FALLBACK_PATH}'"
    html_options[:src] = img_src

    tag(:img, html_options)
  end
end