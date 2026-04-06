class AddUniqueIndexToZonas < ActiveRecord::Migration[8.1]
  def change
    add_index :zonas, [:nombre, :evento_id], unique: true
  end
end