class UnuseFile < ApplicationRecord
  belongs_to :active_site, class_name: 'Site', foreign_key: 'active_site_id', primary_key: 'id', optional: true
  scope :unchecked,  -> { where(active_site_id: nil) }

  def self.export
    headers = %w(ID ファイルパス コンテンツの有無 有効なURL 機種種別)
    return csv_data = ::CSV.generate(headers: headers, write_headers: true, force_quotes: true) do |csv|
      UnuseFile.all.order([:active_site_id,:path, :active_device_type]).each do |u|
        csv <<
        [
          u.id,
          u.path,
          u.active_site_id.nil? ? '無' : '有',
          u.active_site.present? ? "https://" + u.active_site.domain + u.path.chomp : '',
          u.active_device_type
        ]
      end
    end
  end



end
