
class Evento < ApplicationRecord
  # Relaciones
  has_many :zonas, dependent: :destroy

  # Validaciones
  validates :nombre,      presence: { message: "no puede estar en blanco" }
  validates :descripcion, presence: { message: "no puede estar en blanco" }
  validates :fecha,       presence: { message: "no puede estar en blanco" }
  validates :hora,        presence: { message: "no puede estar en blanco" }
  validates :imagen,      presence: { message: "no puede estar en blanco" }
  validates :estado, inclusion: { in: %w[activo cerrado], message: "valor no permitido" }

  # La fecha no puede ser en el pasado (solo al crear)
  validate :fecha_no_en_el_pasado, on: :create

  # Scope para búsqueda
  scope :search_by_name, ->(query) {
    where("nombre ILIKE ? OR descripcion ILIKE ?", "%#{query}%", "%#{query}%")
  }

  # Agotado si está cerrado O si todas sus zonas tienen cupos_disponibles == 0
  def agotado?
    return true if estado == "cerrado"
    return true if zonas.none?
    zonas.all? { |z| z.cupos_disponibles <= 0 }
  end

  private

  def fecha_no_en_el_pasado
    if fecha.present? && fecha < Date.today
      errors.add(:fecha, "no puede ser una fecha pasada")
    end
  end
end
