# ============================================
# Modelo: User
# Descripción: Representa los usuarios del sistema.
# Incluye autenticación mediante Devise.
# ============================================
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :compras

  # Scope para búsqueda de usuarios por nombre o email
  scope :search_by_query, ->(query) {
    where("name ILIKE ? OR email ILIKE ?", "%#{query}%", "%#{query}%")
  }
end
