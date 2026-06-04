class AddUniqueIndexToBoletosTokenQr < ActiveRecord::Migration[8.1]
  def change
    add_index :boletos, :token_qr, unique: true
  end
end