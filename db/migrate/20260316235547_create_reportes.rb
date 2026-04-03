class CreateReportes < ActiveRecord::Migration[8.1]
  def change
    create_table :reportes do |t|
      t.string :tipo
      t.datetime :fecha_generacion

      t.timestamps
    end
  end
end
