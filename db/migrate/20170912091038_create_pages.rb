class CreatePages < ActiveRecord::Migration[5.0]
  def change
    create_table :pages do |t|
      t.integer :site_id
      t.string :path
      t.boolean :active
      t.string :redirect_to

      t.timestamps
    end
  end
end
