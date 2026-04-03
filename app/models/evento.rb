

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
 
  private
 
  def fecha_no_en_el_pasado
    if fecha.present? && fecha < Date.today
      errors.add(:fecha, "no puede ser una fecha pasada")
    end
  end
end
 