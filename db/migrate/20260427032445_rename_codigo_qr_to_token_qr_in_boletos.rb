class RenameCodigoQrToTokenQrInBoletos < ActiveRecord::Migration[8.1]
  def change
    rename_column :boletos, :codigo_qr, :token_qr
  end
end
