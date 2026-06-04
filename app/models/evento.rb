class Evento < ApplicationRecord
  # ── Relaciones ─────────────────
  has_many :zonas, dependent: :destroy

  # ── Soft delete ────────────────
  # "Eliminar" un evento lo oculta del sistema pero conserva todos los datos.
  scope :visible,  -> { where(deleted_at: nil) }
  scope :deleted,  -> { where.not(deleted_at: nil) }

  def soft_delete!
    transaction do
      # Cierra el evento para que nadie más compre
      update!(deleted_at: Time.current, estado: "cerrado")
      # Marca también las zonas como eliminadas
      zonas.update_all(deleted_at: Time.current)
    end
  end

  def eliminado?
    deleted_at.present?
  end

  # ── Validaciones ───────────────
  validates :nombre,      presence: { message: "no puede estar en blanco" }
  validates :descripcion, presence: { message: "no puede estar en blanco" }
  validates :fecha,       presence: { message: "no puede estar en blanco" }
  validates :hora,        presence: { message: "no puede estar en blanco" }
  validates :imagen,      presence: { message: "no puede estar en blanco" }
  validates :estado, inclusion: { in: %w[activo cerrado], message: "valor no permitido" }

  validate :fecha_no_en_el_pasado, on: :create

  # ── Scopes ─────────────────────
  scope :search_by_name, ->(query) {
    where("nombre ILIKE ? OR descripcion ILIKE ?", "%#{query}%", "%#{query}%")
  }

  # ── Helpers ────────────────────
  def agotado?
    return true if estado == "cerrado"
    return true if zonas.none?
    zonas.all? { |z| z.cupos_disponibles <= 0 }
  end

  private

  def fecha_no_en_el_pasado
    if fecha.present? && fecha < Date.today
      errors.add(:fecha, "no puede ser una fecha pasada")  # :nocov:
    end
  end
end
