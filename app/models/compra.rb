# ============================================
# Modelo: Compra
# Descripción: Representa una transacción realizada por un usuario.
# ============================================
class Compra < ApplicationRecord
  belongs_to :user, optional: true
  has_many :boletos, dependent: :destroy
  has_one :pago, dependent: :destroy

  has_one :pago, dependent: :destroy
  has_many :boletos, dependent: :destroy
  has_many :zonas, through: :boletos
  has_many :eventos, -> { distinct }, through: :zonas

  validates :numero_orden, presence: true, uniqueness: true
  validates :cantidad, presence: true, numericality: { greater_than: 0 }
  validates :precio_total, presence: true

  # Validación de email para invitados
  validates :email, presence: { message: "debe proporcionar un correo para recibir su boleto" }, if: -> { user_id.nil? }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "no es válido" }, if: -> { email.present? }
end
