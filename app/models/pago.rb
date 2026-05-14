# ============================================
# Modelo: Pago
# Descripción: Representa el pago asociado a una compra.
# ============================================
class Pago < ApplicationRecord
  belongs_to :compra
  validates :referencia, presence: true
  validates :compra_id, uniqueness: true
  monetize :precio_cents, disable_validation: true, subunits_per_unit: 1
end
