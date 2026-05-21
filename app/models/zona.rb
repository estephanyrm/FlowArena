# ============================================
# Modelo: Zona
# Descripción: Representa una sección dentro de un evento.
# ============================================
class Zona < ApplicationRecord
  belongs_to :evento
  has_many :boletos
  monetize :precio_cents, disable_validation: true, subunits_per_unit: 1

  CAPACIDADES = {
    "Diamante" => 2000,
    "VIP" => 3000,
    "Preferencial" => 3000,
    "General" => 4000
  }

  ZONAS_PERMITIDAS = CAPACIDADES.keys
  validates :nombre, uniqueness: { scope: :evento_id,
            message: "esta zona ya ha sido registrada para este evento" }
  validates :nombre, presence: { message: "debe seleccionar una zona válida" }
  validate :capacidad_dentro_del_tope

  def capacidad_dentro_del_tope
    return if nombre.blank?
    tope = CAPACIDADES[nombre]
    return unless tope
    if capacidad.blank? || capacidad.to_i < 1
      errors.add(:capacidad, "debe ser mayor a 0")
    elsif capacidad.to_i > tope
      errors.add(:capacidad, "no puede superar #{tope} para la zona #{nombre}")
    end
  end

  def cupos_disponibles
    (capacidad || 0) - boletos.count
  end
end
