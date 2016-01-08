Rails.application.routes.draw do

  concern :generic_table do
    get :search_suggestions
  end

  get 'human_resources/' => 'human_resources#index'
  namespace :human_resources do
    get 'settings/' => 'settings#index'
    namespace :settings do
      resources :constants, :holidays, :holiday_types do
        collection do
          concerns :generic_table
        end
      end
    end
    namespace :employee_accounts_management do
    end
    namespace :compensation_and_benefits do
    end
    namespace :attendance do
    end
  end

  get 'general_administrator/' => 'actor#index'
  namespace :actor_search do
    get 'actor_search/' => 'actor#index'
    resource :actors do
      collection do
        concerns :generic_table
      end
    end
  end

  get 'application/reset_search' => 'application#reset_search'



  resources :test, only: :index
  root to: 'home#index'
  match ':controller(/:action(/:id))', :via => [:get, :post]

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/e:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
