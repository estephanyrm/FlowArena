class CreateEventos < ActiveRecord::Migration[8.1]
  def change
    create_table :eventos do |t|
      t.string :nombre
      t.text :descripcion
      t.string :imagen
      t.date :fecha
      t.time :hora
      t.string :estado

      t.timestamps
    end
  end
end
