Rails.application.routes.draw do
  resources :products do
    collection do
      post :sync
    end
  end

  root "products#index"
end
