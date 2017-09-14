class AddColumnsToPages < ActiveRecord::Migration[5.0]
  def change
    add_column :pages, :title, :text, after: :path
    add_column :pages, :h1, :text, after: :title
    add_column :pages, :redirected_page_id, :integer, after: :redirect_to
  end
end
