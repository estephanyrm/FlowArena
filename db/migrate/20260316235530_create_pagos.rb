class CreatePagos < ActiveRecord::Migration[8.1]
  def change
    create_table :pagos do |t|
      t.decimal :monto
      t.datetime :fecha_pago
      t.boolean :estado
      t.string :referencia
      t.references :compra, null: false, foreign_key: true

      t.timestamps
    end
  end
end
