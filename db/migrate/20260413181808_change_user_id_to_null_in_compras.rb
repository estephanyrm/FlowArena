class ChangeUserIdToNullInCompras < ActiveRecord::Migration[8.1]
  def change
    change_column_null :compras, :user_id, true
  end
end
