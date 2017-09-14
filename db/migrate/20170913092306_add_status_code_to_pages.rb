class AddStatusCodeToPages < ActiveRecord::Migration[5.0]
  def change
    add_column :pages, :status_code, :string
  end
end
