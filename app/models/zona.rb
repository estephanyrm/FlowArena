# ============================================
# Modelo: Zona
# Descripción: Representa una sección dentro de un evento.
# ============================================
class Zona < ApplicationRecord
  belongs_to :evento
  has_many :boletos
  monetize :precio_cents, with_currency: :cop

  CAPACIDADES = {
    'Diamante' => 2000,
    'VIP' => 3000,
    'Preferencial' => 3000,
    'General' => 4000
  }

  ZONAS_PERMITIDAS = CAPACIDADES.keys

  validates :nombre, presence: { message: "debe seleccionar una zona válida" }
  validates :capacidad, 
          presence: true, 
          numericality: { 
            only_integer: true, 
            greater_than: 0, 
            less_than: 2_147_483_647, # Límite máximo de 4 bytes
            message: "es un número demasiado grande para el sistema" 
          }
                        
  def cupos_disponibles
    (capacidad || 0) - boletos.count 
  end
end