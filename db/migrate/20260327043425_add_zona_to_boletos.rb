class AddZonaToBoletos < ActiveRecord::Migration[8.1]
  def change
    add_reference :boletos, :zona, null: false, foreign_key: true
  end
end
