# ============================================
# Modelo: Zona
# Descripción: Representa una sección dentro de un evento.
# ============================================
class Zona < ApplicationRecord
  belongs_to :evento
  has_many :boletos, dependent: :destroy
  
  # Usando Money-Rails para manejar el dinero
  monetize :precio_cents, disable_validation: true, subunits_per_unit: 1

  CAPACIDADES = {
    "Diamante" => 2000,
    "VIP" => 3000,
    "Preferencial" => 3000,
    "General" => 4000
  }

  ZONAS_PERMITIDAS = CAPACIDADES.keys
  PRECIO_MAXIMO = 3_000_000

  # Validaciones de presencia y unicidad
  validates :nombre, uniqueness: { 
    scope: :evento_id, 
    message: "esta zona ya ha sido registrada para este evento" 
  }
  validates :nombre, presence: { message: "debe seleccionar una zona válida" }

  # Validación personalizada para el precio
  validate :validar_precio_maximo
  
  # Validación de capacidad
  validate :capacidad_dentro_del_tope

  # Método personalizado para el mensaje de error dinámico
  def validar_precio_maximo
  if precio_cents.blank?
    errors.add(:precio_cents, "no puede estar vacío")
  elsif precio_cents <= 0
    errors.add(:precio_cents, "debe ser mayor a 0")
  elsif precio_cents > PRECIO_MAXIMO
    valor_formateado = ActiveSupport::NumberHelper.number_to_delimited(precio_cents, delimiter: '.')
    tope_formateado = ActiveSupport::NumberHelper.number_to_delimited(PRECIO_MAXIMO, delimiter: '.')
    
    # Usamos :base para que no añada "Precio cents" al principio
    errors.add(:base, "El valor de $#{valor_formateado} COP excede el máximo permitido de $#{tope_formateado} COP")
  end
end

  # Validación de capacidad existente
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
    (capacidad || 0) - (boletos.loaded? ? boletos.size : boletos.count)
  end
end