class CreateZonas < ActiveRecord::Migration[8.1]
  def change
    create_table :zonas do |t|
      t.string :nombre
      t.integer :capacidad
      t.decimal :precio
      t.integer :cupos_disponibles
      t.references :evento, null: false, foreign_key: true

      t.timestamps
    end
  end
end
