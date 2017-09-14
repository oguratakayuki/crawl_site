class LinkFromTo < ApplicationRecord
  belongs_to :from, class_name: 'Page', foreign_key: 'from_page_id', primary_key: 'id'
  belongs_to :to, class_name: 'Page', foreign_key: 'to_page_id', primary_key: 'id'
end
