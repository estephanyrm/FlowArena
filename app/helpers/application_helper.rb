module ApplicationHelper
  def inline_svg(path, options = {})
    file = Rails.root.join("app/assets/images", path)
    svg = File.read(file)
    content_tag(:div, raw(svg), options)
  end
end
