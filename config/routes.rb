# ============================================
# Define todas las rutas de la aplicación
# ============================================
Rails.application.routes.draw do
  devise_for :admins, skip: [:registrations]
  devise_for :users
  root "home#index"
 
  # Ruta del perfil
  get 'perfil', to: 'home#miPerfil', as: 'profile'

  # Ruta de la pagina de eventos
  get 'pagina_eventos', to: 'home#pagina_eventos', as: 'pagina_eventos'
  resources :eventos, only: [:show]

  # Rutas para Compras (RF-06, RF-12)
  resources :compras, only: [:index, :show, :create, :new] do
    member do
      get  :pago
      post :confirmar_pago
    end
  end
  get 'mis_compras', to: 'compras#index', as: 'mis_compras'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  
  namespace :admin do
    get 'dashboard', to: 'dashboard#index'
    resources :eventos do
      resources :zonas 
    end
    resources :usuarios
    resources :reportes, only: [:index] do
      collection { get :export }
    end
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end