class AddSizeAndStatusCodeToUnuseFiles < ActiveRecord::Migration[5.0]
  def change
    add_column :unuse_files, :size, :integer
    add_column :unuse_files, :status_code, :string
  end
end
