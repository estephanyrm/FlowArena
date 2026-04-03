class CreateCompras < ActiveRecord::Migration[8.1]
  def change
    create_table :compras do |t|
      t.string :numero_orden
      t.integer :cantidad
      t.decimal :precio_total
      t.datetime :fecha_compra
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
