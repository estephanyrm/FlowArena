# ============================================
# Modelo: User
# Descripción: Representa los usuarios del sistema.
# Incluye autenticación mediante Devise.
# ============================================
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :compras
end
