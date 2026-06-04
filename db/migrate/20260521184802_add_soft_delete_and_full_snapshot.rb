class AddSoftDeleteAndFullSnapshot < ActiveRecord::Migration[8.1]
  def change
    # ── Soft delete ─────────────
    add_column :eventos, :deleted_at, :datetime
    add_column :zonas,   :deleted_at, :datetime

    add_index :eventos, :deleted_at
    add_index :zonas,   :deleted_at

    # ── Snapshot extendido en boletos ──────────────────────────────────────
    # nombre_zona y nombre_evento ya existen (migración 20260521180526).
    # Agregamos los campos que faltan para que el boleto sea 100% autónomo.
    add_column :boletos, :fecha_evento,       :date
    add_column :boletos, :hora_evento,        :time
    add_column :boletos, :precio_boleto_cents, :integer

    # Poblar snapshot en boletos existentes que aún tienen zona/evento vivos
    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE boletos b
          SET
            nombre_zona        = z.nombre,
            nombre_evento      = e.nombre,
            fecha_evento       = e.fecha,
            hora_evento        = e.hora,
            precio_boleto_cents = z.precio_cents
          FROM zonas z
          JOIN eventos e ON e.id = z.evento_id
          WHERE b.zona_id = z.id
            AND (
              b.nombre_zona        IS NULL OR
              b.nombre_evento      IS NULL OR
              b.fecha_evento       IS NULL OR
              b.hora_evento        IS NULL OR
              b.precio_boleto_cents IS NULL
            );
        SQL
      end
    end
  end
end