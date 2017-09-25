class CreateUnuseFiles < ActiveRecord::Migration[5.0]
  def change
    create_table :unuse_files do |t|
      t.string :path

      t.timestamps
    end
  end
end
