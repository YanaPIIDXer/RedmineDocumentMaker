# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do
    resources :projects do
        get 'main', :to => 'main#index'
    end
end
