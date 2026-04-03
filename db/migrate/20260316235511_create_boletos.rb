class CreateBoletos < ActiveRecord::Migration[8.1]
  def change
    create_table :boletos do |t|
      t.string :codigo_qr
      t.boolean :usado
      t.datetime :fecha_generacion
      t.references :compra, null: false, foreign_key: true

      t.timestamps
    end
  end
end
