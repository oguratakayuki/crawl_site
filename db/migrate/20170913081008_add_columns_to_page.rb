class AddColumnsToPage < ActiveRecord::Migration[5.0]
  def change
    add_column :pages, :empty_contents, :boolean
  end
end
