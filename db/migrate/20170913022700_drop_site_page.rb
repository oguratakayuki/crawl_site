class DropSitePage < ActiveRecord::Migration[5.0]
  def change
    drop_table :site_pages
  end
end
