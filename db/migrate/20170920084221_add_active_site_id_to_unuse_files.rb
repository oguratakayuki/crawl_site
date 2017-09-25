class AddActiveSiteIdToUnuseFiles < ActiveRecord::Migration[5.0]
  def change
    add_column :unuse_files, :active_site_id, :integer
    add_column :unuse_files, :active_device_type, :string
  end
end
