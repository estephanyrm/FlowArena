class Boleto < ApplicationRecord
  belongs_to :zona
  belongs_to :compra

  # Validación de uso 
  def usado?
    usado == true
  end

  #  Snapshot helpers 
  # Estos métodos devuelven el dato del snapshot si la zona/evento ya no
  # existe en la BD (fue eliminado con soft-delete o por error previo).

  def nombre_zona_safe
    nombre_zona.presence || zona&.nombre || "—"
  end

  def nombre_evento_safe
    nombre_evento.presence || zona&.evento&.nombre || "—"
  end

  def fecha_evento_safe
    fecha_evento.presence || zona&.evento&.fecha
  end

  def hora_evento_safe
    hora_evento.presence || zona&.evento&.hora
  end

  def precio_boleto_safe
    precio_boleto_cents.presence || zona&.precio_cents || 0
  end
end