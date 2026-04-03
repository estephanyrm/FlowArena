# ============================================
# Modelo: Admin
# Descripción: Representa los administradores del sistema.
# ============================================
class Admin < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
