Rails.application.routes.draw do
  resources :unuse_files do
    get 'check', on: :collection
    get 'download', on: :collection
  end
  resources :link_from_tos
  resources :sites do
    resources :pages do
      get 'crawl', on: :collection
      get 'search'
      get 'download', on: :collection
    end
    post 'detect_unuse', on: :collection
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
