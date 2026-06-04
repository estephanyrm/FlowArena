class FixBoletosZonaCascade < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :boletos, :zonas
    add_foreign_key :boletos, :zonas, on_delete: :cascade
  end

  def down
    remove_foreign_key :boletos, :zonas
    add_foreign_key :boletos, :zonas
  end
end