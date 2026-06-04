class AddSnapshotToBoletos < ActiveRecord::Migration[8.1]
  def change
    add_column :boletos, :nombre_zona,   :string
    add_column :boletos, :nombre_evento, :string
  end
end