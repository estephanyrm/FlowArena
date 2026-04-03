# ============================================
# Modelo: Compra
# Descripción: Representa una transacción realizada por un usuario.
# ============================================
class Compra < ApplicationRecord
   belongs_to :user
  has_many :boletos, dependent: :destroy
  has_one :pago, dependent: :destroy

  monetize :precio_total_cents, with_currency: :cop
end
