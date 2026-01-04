Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API endpoints (versioned)
  namespace :api do
    namespace :v1 do
      post "encode", to: "urls#encode"
      get "decode", to: "urls#decode"
    end
  end

  # Web controller endpoints (for frontend form)
  post "encode", to: "urls#encode"
  get "decode", to: "urls#decode"

  # Home page with form UI
  root "urls#home"

  # Redirect short URLs to original URLs
  get ":short_code", to: "urls#redirect", as: :short_url, constraints: { short_code: /[a-zA-Z0-9]{6}/ }
end
