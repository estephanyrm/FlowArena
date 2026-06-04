class FixTodoSnapshot < ActiveRecord::Migration[8.1]
  def up
    # ── 1. Cambiar FK boletos→zonas: de cascade a nullify ─────────────────
    # Con cascade: borrar una zona borraba el boleto. Con nullify: zona_id
    # queda en NULL pero el boleto sobrevive con su snapshot.
    remove_foreign_key :boletos, :zonas
    add_foreign_key :boletos, :zonas, on_delete: :nullify

    # Permitir zona_id NULL (antes era NOT NULL)
    change_column_null :boletos, :zona_id, true

    # ── 2. Agregar columnas de snapshot extendido ──────────────────────────
    add_column :boletos, :fecha_evento,        :date    unless column_exists?(:boletos, :fecha_evento)
    add_column :boletos, :hora_evento,         :time    unless column_exists?(:boletos, :hora_evento)
    add_column :boletos, :precio_boleto_cents, :integer unless column_exists?(:boletos, :precio_boleto_cents)

    # ── 3. Soft delete en eventos y zonas ─────────────────────────────────
    add_column :eventos, :deleted_at, :datetime unless column_exists?(:eventos, :deleted_at)
    add_column :zonas,   :deleted_at, :datetime unless column_exists?(:zonas,   :deleted_at)

    add_index :eventos, :deleted_at unless index_exists?(:eventos, :deleted_at)
    add_index :zonas,   :deleted_at unless index_exists?(:zonas,   :deleted_at)

    # ── 4. Rellenar snapshot en boletos que aún tienen zona viva ──────────
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
      WHERE b.zona_id = z.id;
    SQL
  end

  def down
    remove_foreign_key :boletos, :zonas
    add_foreign_key :boletos, :zonas, on_delete: :cascade
    change_column_null :boletos, :zona_id, false
    remove_column :boletos, :fecha_evento        if column_exists?(:boletos, :fecha_evento)
    remove_column :boletos, :hora_evento         if column_exists?(:boletos, :hora_evento)
    remove_column :boletos, :precio_boleto_cents if column_exists?(:boletos, :precio_boleto_cents)
    remove_column :eventos, :deleted_at          if column_exists?(:eventos, :deleted_at)
    remove_column :zonas,   :deleted_at          if column_exists?(:zonas,   :deleted_at)
  end
end