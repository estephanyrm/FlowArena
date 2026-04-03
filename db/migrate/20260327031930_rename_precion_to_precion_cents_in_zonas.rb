class RenamePrecionToPrecionCentsInZonas < ActiveRecord::Migration[8.1]
  def change
    rename_column :zonas, :precio, :precio_cents
    change_column :zonas, :precio_cents, :integer
  end
end