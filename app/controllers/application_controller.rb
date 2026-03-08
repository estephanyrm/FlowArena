class ApplicationController < ActionController::Base
  # Llama al método antes de ejecutar cualquier acción de Devise
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    # Permite el campo :name para el registro (sign_up)
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    
    # También permite :name si el usuario decide editar su perfil más adelante
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def flash_to_headers
    return unless request.xhr?
    response.headers['X-Flash-Messages'] = flash_hash.to_json
    flash.discard # Evita que el mensaje aparezca en la siguiente carga
  end

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
