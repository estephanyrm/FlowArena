class AddEstadoToComprasAndBoletos < ActiveRecord::Migration[8.1]
  def change
    add_column :compras,  :estado, :string, default: "pendiente"
    add_column :boletos,  :estado, :string, default: "pendiente"
  end
end
