json.extract! site, :id, :domain, :name, :url, :created_at, :updated_at
json.url site_url(site, format: :json)
