class Page < ApplicationRecord
  belongs_to :redirected_page, class_name: 'Page', foreign_key: 'redirected_page_id', primary_key: 'id', optional: true
  belongs_to :site
  has_many :link_froms, class_name: 'LinkFromTo', foreign_key: 'to_page_id', primary_key: 'id'
  has_many :link_tos, class_name: 'LinkFromTo', foreign_key: 'from_page_id', primary_key: 'id'
  has_many :froms, class_name: 'Page', through: :link_froms, primary_key: 'from_page_id'
  has_many :tos, class_name: 'Page', through: :link_tos, primary_key: 'to_page_id'
  scope :active,  -> { where(active: true) }
  scope :by_path,  ->(path) { where(path: path) }
  scope :by_device_type, ->(device_type) do
    if device_type.try(:present?)
      where(device_type: device_type)
    else
      where("1=1")
    end
  end
  scope :of_primal_sites, -> { where(site_id: %w(1 2 3 4)) }

  def paths_to_end_of_redirections(paths=[])
    paths = paths << path
    if redirected_page
      redirected_page.paths_to_end_of_redirections(paths)
    else
      return paths
    end
  end

  def full_path
    URI.join(site.url, path)
  rescue StandardError
    "不正なリンク(#{path})"
  end

end
