
class LoadTestController < ApplicationController
  skip_before_action :verify_authenticity_token

  # Solo disponible en development y test
  before_action :require_non_production
  before_action :require_load_test_token

  # Elimina todas las compras cuyo email empiece con el prefijo dado,
  # incluyendo sus boletos y pagos asociados (por dependent: :destroy).
  def cleanup
    body   = JSON.parse(request.body.read) rescue {}
    prefix = body["prefix"].to_s.strip

    if prefix.blank? || prefix.length < 2 || !prefix.match?(/\Ak6_/)
      return render json: { error: "Prefijo inválido. Debe empezar con 'k6_'." },
                    status: :bad_request
    end

    # Busca compras de prueba por email (dominio .invalid = nunca real)
    compras = Compra.where("email LIKE ?", "#{prefix}%@loadtest.invalid")
    deleted = compras.count

    # destroy_all respeta los callbacks y los dependent: :destroy del modelo
    compras.destroy_all

    # También limpia usuarios de prueba si los hubiera
    users_deleted = User.where("email LIKE ?", "#{prefix}%@loadtest.invalid").destroy_all.count

    render json: {
      ok:             true,
      deleted:        deleted,
      users_deleted:  users_deleted,
      prefix:         prefix,
      timestamp:      Time.current.iso8601
    }
  end

  private

  def require_non_production
    if Rails.env.production?
      render json: { error: "No disponible en producción." }, status: :forbidden
    end
  end

  def require_load_test_token
    expected_token = ENV.fetch("LOAD_TEST_TOKEN", "dev-cleanup-token")
    provided_token = request.headers["X-Load-Test-Token"].to_s

    unless ActiveSupport::SecurityUtils.secure_compare(expected_token, provided_token)
      render json: { error: "Token inválido." }, status: :unauthorized
    end
  end
end