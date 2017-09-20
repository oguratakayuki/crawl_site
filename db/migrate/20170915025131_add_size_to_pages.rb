class AddSizeToPages < ActiveRecord::Migration[5.0]
  def change
    add_column :pages, :size, :integer
  end
end
