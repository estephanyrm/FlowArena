# ============================================
# Modelo: Pago
# Descripción: Representa el pago asociado a una compra.
# ============================================
class Pago < ApplicationRecord
  belongs_to :compra
  monetize :monto_cents, with_currency: :cop
end
