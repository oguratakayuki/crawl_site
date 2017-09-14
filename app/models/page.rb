class Page < ApplicationRecord
  scope :by_path,  ->(path) { where(path: path) }
  belongs_to :redirected_page, class_name: 'Page', foreign_key: 'redirected_page_id', primary_key: 'id', optional: true
  belongs_to :site
  has_many :link_froms, class_name: 'LinkFromTo', foreign_key: 'to_page_id', primary_key: 'id'
  has_many :link_tos, class_name: 'LinkFromTo', foreign_key: 'from_page_id', primary_key: 'id'
  has_many :froms, class_name: 'Page', through: :link_froms, primary_key: 'from_page_id'
  has_many :tos, class_name: 'Page', through: :link_tos, primary_key: 'to_page_id'
  def paths_to_end_of_redirections(paths=[])
    paths = paths << path
    if redirected_page
      redirected_page.paths_to_end_of_redirections(paths)
    else
      return paths
    end
  end
end
