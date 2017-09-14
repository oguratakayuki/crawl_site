class CreateLinkFromTos < ActiveRecord::Migration[5.0]
  def change
    create_table :link_from_tos do |t|
      t.integer :from_page_id
      t.integer :to_page_id
      t.boolean :by_redirection

      t.timestamps
    end
  end
end
