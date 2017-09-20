class DropColumnsFromPages < ActiveRecord::Migration[5.0]
  def change
    remove_column :pages, :pc_accesible, :boolean
    remove_column :pages, :mobile_accesible, :boolean
    add_column    :pages, :device_type, :string
  end
end
