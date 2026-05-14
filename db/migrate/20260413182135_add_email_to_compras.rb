class AddEmailToCompras < ActiveRecord::Migration[8.1]
  def change
    add_column :compras, :email, :string
  end
end
