class CreateSites < ActiveRecord::Migration[5.0]
  def change
    create_table :sites do |t|
      t.string :domain
      t.string :name
      t.string :url

      t.timestamps
    end
  end
end
