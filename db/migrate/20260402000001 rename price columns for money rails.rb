class RenamePriceColumnsForMoneyRails < ActiveRecord::Migration[8.1]
  def up
    # zonas: precio (decimal) -> precio_cents (integer)
    rename_column :zonas,    :precio,       :precio_cents
    change_column :zonas,    :precio_cents, :integer, default: 0, null: false

    # compras: precio_total (decimal) -> precio_total (integer)
    rename_column :compras,  :precio_total,       :precio_total
    change_column :compras,  :precio_total, :integer, default: 0, null: false

    # pagos: monto (decimal) -> monto (integer)
    rename_column :pagos,    :monto,       :monto
    change_column :pagos,    :monto, :integer, default: 0, null: false
  end

  def down
    rename_column :zonas,   :precio_cents,       :precio
    change_column :zonas,   :precio,             :decimal

    rename_column :compras, :precio_total, :precio_total
    change_column :compras, :precio_total,       :decimal

    rename_column :pagos,   :monto,        :monto
    change_column :pagos,   :monto,              :decimal
  end
end