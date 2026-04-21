Rails.application.routes.draw do
  get "/health", to: proc { [200, {}, ["OK"]] }
  devise_for :users, controllers: {
    sessions:      "users/sessions",
    registrations: "users/registrations"
  }

  scope "/:company_slug" do
    namespace :employee do
      get  "dashboard", to: "dashboard#show", as: :dashboard

      resources :savings_plans, only: [:index, :show, :new, :create] do
        resources :withdrawal_requests, only: [:new, :create], shallow: true
      end

      resources :salary_advances, only: [:index, :show, :new, :create]
      resources :transactions,    only: [:index]
      resources :notifications,   only: [:index] do
        member { patch :mark_read }
      end

      get "profile",   to: "profiles#show",   as: :profile
      get "documents", to: "documents#index", as: :documents

      resources :leave_requests, only: [:index, :new, :create, :destroy]
      resources :rotas,          only: [:index, :show]
      resources :payslips,       only: [:index, :show]
    end

    namespace :admin do
      get "dashboard", to: "dashboard#show", as: :dashboard

      resources :savings_plans, only: [] do
        member do
          get  :approve_form
          get  :decline_form
          patch :approve
          patch :decline
        end
      end

      resources :withdrawal_requests, only: [] do
        member do
          get  :approve_form
          get  :decline_form
          patch :approve
          patch :decline
        end
      end

      resources :salary_advances, only: [:show] do
        member do
          get  :approve_form
          get  :decline_form
          get  :disburse_form
          patch :approve
          patch :decline
          patch :disburse
        end
      end

      resources :company_memberships, only: [:index, :new, :create, :edit, :update, :destroy]
      resources :departments,         only: [:index, :new, :create, :edit, :update, :destroy]
      resources :teams,               only: [:index, :show, :new, :create, :edit, :update, :destroy]
      resources :leave_types,         only: [:index, :new, :create, :edit, :update]

      resources :payroll_runs, only: [:index, :new, :create, :show] do
        member do
          patch :finalise
          patch :reopen
          patch :send_payslips
          get   :export_csv
        end
        resources :payroll_entries, only: [:edit, :update] do
          member do
            delete :destroy_item
          end
        end
      end

      resources :leave_requests, only: [:index] do
        member do
          patch :approve
          patch :decline
        end
      end

      resources :leave_balances, only: [:create] do
        member { patch :override }
      end

      resources :rotas, only: [:index, :new, :create, :show] do
        member { patch :publish }
        resources :rota_entries, only: [:create, :update, :destroy]
      end

      resources :employee_profiles, only: [:index, :show, :edit, :update] do
        resources :employment_histories, only: [:new, :create, :edit, :update, :destroy]
        resources :salary_histories,     only: [:index, :new, :create]
        resources :bank_details,         only: [:show, :new, :create]
        resources :documents,            only: [:index, :new, :create, :destroy]
        resources :emergency_contacts,   only: [:index, :new, :create, :edit, :update, :destroy]
        resources :employee_references,  only: [:index, :new, :create, :edit, :update]
      end
    end
  end

  get   "/invitations/:token/accept", to: "invitations#show",   as: :accept_invitation
  patch "/invitations/:token/accept", to: "invitations#update"

  get  "/register", to: "registrations#new",    as: :new_registration
  post "/register", to: "registrations#create", as: :registration

  root to: "pages#home"
end
