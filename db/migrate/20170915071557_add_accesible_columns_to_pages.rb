class AddAccesibleColumnsToPages < ActiveRecord::Migration[5.0]
  def change
    add_column :pages, :pc_accesible, :boolean
    add_column :pages, :mobile_accesible, :boolean
  end
end
