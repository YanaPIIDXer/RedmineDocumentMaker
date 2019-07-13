# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do
    resources :projects do
        get 'main', :to => 'main#index'
        post 'make', :to => 'makepdf#make'
    end
end
