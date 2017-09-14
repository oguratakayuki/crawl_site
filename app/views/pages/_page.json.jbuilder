json.extract! page, :id, :site_id, :path, :active, :redirect_to, :created_at, :updated_at
json.url page_url(page, format: :json)
