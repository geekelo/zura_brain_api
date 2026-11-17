Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :admin do
    match "clients/preferences", to: "clients#update_preferences", via: [:patch, :put]
    resources :clients, only: [:index, :show, :create, :update, :destroy]

    resources :therapists, only: [:index, :show, :create], param: :code
    match "therapists/:code/status", to: "therapists#update_status", via: [:patch, :put]

    get "sessions", to: "sessions#index"
    post "sessions", to: "sessions#create"
    match "sessions/:ss/comments", to: "sessions#add_comment", via: [:patch, :put]
    match "sessions/:ss/comments/resolve", to: "sessions#resolve_comment", via: [:patch, :put]
    match "sessions/:ss/transaction_id", to: "sessions#update_transaction_id", via: [:patch, :put]
    match "sessions/:ss/status", to: "sessions#update_status", via: [:patch, :put]
    match "sessions/:ss/verify_payment", to: "sessions#verify_payment", via: [:patch, :put]
    match "sessions/:ss/times", to: "sessions#start_end_session", via: [:patch, :put]
    match "sessions/:ss", to: "sessions#update", via: [:patch, :put]
    delete "sessions/:id", to: "sessions#destroy"

    post "session_therapists", to: "session_therapists#create"
    delete "session_therapists", to: "session_therapists#destroy"
    post "session_therapists/tip", to: "session_therapists#tip"

    resources :session_activities, only: [:create, :update, :destroy], param: :session_activity_id

    resources :admin_notes, only: [:index, :create]
    match "admin_notes/:admin_note_id", to: "admin_notes#update", via: [:patch, :put]
    delete "admin_notes/:an", to: "admin_notes#destroy"

    resources :payment_methods, only: [:create, :update, :destroy] do
      member do
        post :receipt, action: :upload_receipt
      end
    end
    resources :main_account_expenses, only: [:create, :update, :destroy]

    resources :therapist_accounts, only: [:create]
    resources :therapist_payins_payouts, only: [:create, :update, :destroy]

    get "tech_accounts", to: "tech_accounts#index"
    resources :tech_account_summaries, only: [:create]
    resources :tech_payins_payouts, only: [:create, :update, :destroy], param: :tech_account_id

    get "extra_accounts", to: "extra_accounts#index"
    resources :extra_account_summaries, only: [:create]
    resources :extra_account_payins_payouts, only: [:create, :update, :destroy], param: :extra_account_payin_payout_id

    resources :lunez_account_summaries, only: [:create]
    get "lunez_accounts", to: "lunez_accounts#index"
    get "main_accounts", to: "main_accounts#index"
    resources :main_account_summaries, only: [:create]
  end

  namespace :pos do
    match "clients/preferences", to: "clients#update_preferences", via: [:patch, :put]
    resources :clients, only: [:index, :show, :create, :update, :destroy]

    resources :therapists, only: [:index, :show, :create], param: :code
    match "therapists/:code/status", to: "therapists#update_status", via: [:patch, :put]

    get "sessions", to: "sessions#index"
    post "sessions", to: "sessions#create"
    match "sessions/:ss/comments", to: "sessions#add_comment", via: [:patch, :put]
    match "sessions/:ss/comments/resolve", to: "sessions#resolve_comment", via: [:patch, :put]
    match "sessions/:ss/transaction_id", to: "sessions#update_transaction_id", via: [:patch, :put]
    match "sessions/:ss/status", to: "sessions#update_status", via: [:patch, :put]
    match "sessions/:ss/verify_payment", to: "sessions#verify_payment", via: [:patch, :put]
    match "sessions/:ss/times", to: "sessions#start_end_session", via: [:patch, :put]
    match "sessions/:ss", to: "sessions#update", via: [:patch, :put]
    delete "sessions/:id", to: "sessions#destroy"

    post "session_therapists", to: "session_therapists#create"
    delete "session_therapists", to: "session_therapists#destroy"
    post "session_therapists/tip", to: "session_therapists#tip"

    resources :session_activities, only: [:create, :update, :destroy], param: :session_activity_id

    resources :admin_notes, only: [:index, :create]
    match "admin_notes/:admin_note_id", to: "admin_notes#update", via: [:patch, :put]
    delete "admin_notes/:an", to: "admin_notes#destroy"

    resources :payment_methods, only: [:create, :update, :destroy] do
      member do
        post :receipt, action: :upload_receipt
      end
    end
    resources :main_account_expenses, only: [:create, :update, :destroy]

    resources :therapist_accounts, only: [:create]
    resources :therapist_payins_payouts, only: [:create, :update, :destroy]

    resources :tech_account_summaries, only: [:create]
    resources :tech_payins_payouts, only: [:create, :update, :destroy], param: :tech_account_id

    resources :extra_account_summaries, only: [:create]
    resources :extra_account_payins_payouts, only: [:create, :update, :destroy], param: :extra_account_payin_payout_id

    resources :lunez_account_summaries, only: [:create]
    resources :main_account_summaries, only: [:create]
  end
end
