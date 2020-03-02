Rails.application.routes.draw do
  # No Devise modules are enabled
  # Custom Warden strategy is used instead see app/warden/magic_link_token.rb
  # Custom views are used, see app/views/magic_link/sign_up/
  devise_for :candidates, skip: :all

  devise_scope :candidate do
    get '/candidate/sign-out', to: 'devise/sessions#destroy', as: :candidate_interface_sign_out
  end

  if HostingEnvironment.sandbox_mode?
    root to: 'content#sandbox'
  else
    root to: redirect('/candidate')
  end

  namespace :candidate_interface, path: '/candidate' do
    get '/' => 'start_page#show', as: :start

    get '/accessibility', to: 'content#accessibility'
    get '/privacy-policy', to: 'content#privacy_policy', as: :privacy_policy
    get '/cookies', to: 'content#cookies_candidate', as: :cookies
    get '/terms-of-use', to: 'content#terms_candidate', as: :terms
    get '/providers', to: 'content#providers', as: :providers

    get '/eligibility' => 'start_page#eligibility', as: :eligibility
    post '/eligibility' => 'start_page#determine_eligibility'
    get '/not-eligible', to: 'start_page#not_eligible', as: :not_eligible

    get '/sign-up', to: 'sign_up#new', as: :sign_up
    post '/sign-up', to: 'sign_up#create'
    get '/sign-up/check-email', to: 'sign_in#check_your_email', as: :check_email_sign_up

    get '/sign-in', to: 'sign_in#new', as: :sign_in
    post '/sign-in', to: 'sign_in#create'
    post '/sign-in/expired', to: 'sign_in#create_from_expired_token', as: :create_expired_sign_in
    get '/sign-in/check-email', to: 'sign_in#check_your_email', as: :check_email_sign_in
    get '/sign-in/expired', to: 'sign_in#expired', as: :expired_sign_in

    get '/authenticate', to: 'sign_in#authenticate', as: :authenticate

    get '/apply', to: 'apply_from_find#show', as: :apply_from_find

    get '/interstitial', to: 'sign_in#interstitial', as: :interstitial

    scope '/application' do
      get '/' => 'application_form#show', as: :application_form
      get '/edit' => 'application_form#edit', as: :application_edit
      get '/review' => 'application_form#review', as: :application_review
      get '/review/submitted' => 'application_form#review_submitted', as: :application_review_submitted
      get '/complete' => 'application_form#complete', as: :application_complete
      get '/submit' => 'application_form#submit_show', as: :application_submit_show
      post '/submit' => 'application_form#submit', as: :application_submit
      get '/submit-success' => 'application_form#submit_success', as: :application_submit_success

      scope '/personal-details' do
        get '/' => 'personal_details#edit', as: :personal_details_edit
        post '/review' => 'personal_details#update', as: :personal_details_update
        get '/review' => 'personal_details#show', as: :personal_details_show
      end

      scope '/personal-statement' do
        get '/becoming-a-teacher' => 'personal_statement/becoming_a_teacher#edit', as: :becoming_a_teacher_edit
        post '/becoming-a-teacher/review' => 'personal_statement/becoming_a_teacher#update', as: :becoming_a_teacher_update
        get '/becoming-a-teacher/review' => 'personal_statement/becoming_a_teacher#show', as: :becoming_a_teacher_show

        get '/subject-knowledge' => 'personal_statement/subject_knowledge#edit', as: :subject_knowledge_edit
        post '/subject-knowledge/review' => 'personal_statement/subject_knowledge#update', as: :subject_knowledge_update
        get '/subject-knowledge/review' => 'personal_statement/subject_knowledge#show', as: :subject_knowledge_show

        get '/interview-preferences' => 'personal_statement/interview_preferences#edit', as: :interview_preferences_edit
        post '/interview-preferences/review' => 'personal_statement/interview_preferences#update', as: :interview_preferences_update
        get '/interview-preferences/review' => 'personal_statement/interview_preferences#show', as: :interview_preferences_show
      end

      scope '/training-with-a-disability' do
        get '/' => 'training_with_a_disability#edit', as: :training_with_a_disability_edit
        post '/review' => 'training_with_a_disability#update', as: :training_with_a_disability_update
        get '/review' => 'training_with_a_disability#show', as: :training_with_a_disability_show
      end

      scope '/contact-details' do
        get '/' => 'contact_details/base#edit', as: :contact_details_edit_base
        post '/' => 'contact_details/base#update', as: :contact_details_update_base

        get '/address' => 'contact_details/address#edit', as: :contact_details_edit_address
        post '/address' => 'contact_details/address#update', as: :contact_details_update_address

        get '/review' => 'contact_details/review#show', as: :contact_details_review
      end

      scope '/gcse/:subject', constraints: { subject: /(maths|english|science)/ } do
        get '/' => 'gcse/type#edit', as: :gcse_details_edit_type
        post '/' => 'gcse/type#update', as: :gcse_details_update_type

        get '/grade' => 'gcse/grade#edit', as: :gcse_details_edit_grade
        patch '/grade' => 'gcse/grade#update', as: :gcse_details_update_grade

        get '/year' => 'gcse/year#edit', as: :gcse_details_edit_year
        patch '/year' => 'gcse/year#update', as: :gcse_details_update_year

        get '/review' => 'gcse/review#show', as: :gcse_review
      end

      scope '/work-history' do
        get '/length' => 'work_history/length#show', as: :work_history_length
        post '/length' => 'work_history/length#submit'

        get '/missing' => 'work_history/explanation#show', as: :work_history_explanation
        post '/missing' => 'work_history/explanation#submit'

        get '/explain-breaks' => 'work_history/breaks#edit', as: :work_history_breaks
        post '/explain-breaks' => 'work_history/breaks#update'

        get '/explain-break/new' => 'work_history/break#new', as: :new_work_history_break
        post '/explain-break/new' => 'work_history/break#create'
        get '/explain-break/edit/:id' => 'work_history/break#edit', as: :edit_work_history_break
        post '/explain-break/edit/:id' => 'work_history/break#update'
        get '/explain-break/delete/:id' => 'work_history/break#confirm_destroy', as: :destroy_work_history_break
        post '/explain-break/delete/:id' => 'work_history/break#destroy'

        get '/new' => 'work_history/edit#new', as: :work_history_new
        post '/create' => 'work_history/edit#create', as: :work_history_create

        get '/edit/:id' => 'work_history/edit#edit', as: :work_history_edit
        post '/edit/:id' => 'work_history/edit#update'

        get '/review' => 'work_history/review#show', as: :work_history_show
        patch '/review' => 'work_history/review#complete', as: :work_history_complete

        get '/delete/:id' => 'work_history/destroy#confirm_destroy', as: :work_history_destroy
        delete '/delete/:id' => 'work_history/destroy#destroy'
      end

      scope '/school-experience' do
        get '/' => 'volunteering/experience#show', as: :volunteering_experience
        post '/' => 'volunteering/experience#submit'

        get '/new' => 'volunteering/base#new', as: :new_volunteering_role
        post '/new' => 'volunteering/base#create', as: :create_volunteering_role

        get '/edit/:id' => 'volunteering/base#edit', as: :edit_volunteering_role
        post '/edit/:id' => 'volunteering/base#update'

        get '/review' => 'volunteering/review#show', as: :review_volunteering
        patch '/review' => 'volunteering/review#complete', as: :complete_volunteering

        get '/delete/:id' => 'volunteering/destroy#confirm_destroy', as: :confirm_destroy_volunteering_role
        delete '/delete/:id' => 'volunteering/destroy#destroy'
      end

      scope '/degrees' do
        get '/' => 'degrees/base#new', as: :degrees_new_base
        post '/' => 'degrees/base#create', as: :degrees_create_base

        get '/:id/grade' => 'degrees/grade#new', as: :degrees_grade
        get '/:id/grade/edit' => 'degrees/grade#edit', as: :degrees_grade_edit
        post '/:id/grade' => 'degrees/grade#update', as: :degrees_create_grade

        get '/:id/year' => 'degrees/year#new', as: :degrees_year
        get '/:id/year/edit' => 'degrees/year#edit', as: :degrees_year_edit
        post '/:id/year' => 'degrees/year#update', as: :degrees_create_year

        get '/review' => 'degrees/review#show', as: :degrees_review
        patch '/review' => 'degrees/review#complete', as: :degrees_complete

        get '/edit/:id' => 'degrees/base#edit', as: :degrees_edit
        post '/edit/:id' => 'degrees/base#update'

        get '/delete/:id' => 'degrees/destroy#confirm_destroy', as: :confirm_degrees_destroy
        delete '/delete/:id' => 'degrees/destroy#destroy'
      end

      scope '/courses' do
        get '/' => 'course_choices#index', as: :course_choices_index

        get '/choose' => 'course_choices#have_you_chosen', as: :course_choices_choose
        post '/choose' => 'course_choices#make_choice'

        get '/find_a_course' => 'course_choices#go_to_find', as: :go_to_find

        get '/delete/:id' => 'course_choices#confirm_destroy', as: :confirm_destroy_course_choice
        delete '/delete/:id' => 'course_choices#destroy'

        get '/provider' => 'course_choices#options_for_provider', as: :course_choices_provider
        post '/provider' => 'course_choices#pick_provider'

        get '/apply-on-ucas' => 'course_choices#ucas', as: :course_choices_on_ucas

        get '/provider/:provider_id/courses' => 'course_choices#options_for_course', as: :course_choices_course
        post '/provider/:provider_id/courses' => 'course_choices#pick_course'

        get '/provider/:provider_id/courses/:course_id' => 'course_choices#options_for_study_mode', as: :course_choices_study_mode
        post '/provider/:provider_id/courses/:course_id' => 'course_choices#pick_study_mode'

        get '/provider/:provider_id/courses/:course_id/:study_mode' => 'course_choices#options_for_site', as: :course_choices_site
        post '/provider/:provider_id/courses/:course_id/:study_mode' => 'course_choices#pick_site'

        get '/review' => 'course_choices#review', as: :course_choices_review
        patch '/review' => 'course_choices#complete', as: :course_choices_complete
      end

      scope '/choice/:id' do
        get '/offer' => 'decisions#offer', as: :offer
        post '/offer/respond' => 'decisions#respond_to_offer', as: :respond_to_offer

        get '/offer/decline' => 'decisions#decline', as: :decline_offer
        post '/offer/decline' => 'decisions#confirm_decline'

        get '/offer/accept' => 'decisions#accept', as: :accept_offer
        post '/offer/accept' => 'decisions#confirm_accept'

        get '/withdraw' => 'decisions#withdraw', as: :withdraw
        post '/withdraw' => 'decisions#confirm_withdraw'
      end

      scope '/other-qualifications' do
        get '/' => 'other_qualifications/base#new', as: :new_other_qualification
        post '/' => 'other_qualifications/base#create', as: :create_other_qualification

        get '/review' => 'other_qualifications/review#show', as: :review_other_qualifications
        patch '/review' => 'other_qualifications/review#complete', as: :complete_other_qualifications

        get '/edit/:id' => 'other_qualifications/base#edit', as: :edit_other_qualification
        post '/edit/:id' => 'other_qualifications/base#update'

        get '/delete/:id' => 'other_qualifications/destroy#confirm_destroy', as: :confirm_destroy_other_qualification
        delete '/delete/:id' => 'other_qualifications/destroy#destroy'
      end

      scope '/referees' do
        get '/' => 'referees#index', as: :referees
        get '/new' => 'referees#new', as: :new_referee
        post '/' => 'referees#create'

        get '/review' => 'referees#review', as: :review_referees
        patch '/review' => 'referees#complete', as: :complete_referees

        get '/edit/:id' => 'referees#edit', as: :edit_referee
        patch '/update/:id' => 'referees#update', as: :update_referee

        get '/delete/:id' => 'referees#confirm_destroy', as: :confirm_destroy_referee
        delete '/delete/:id' => 'referees#destroy', as: :destroy_referee
      end

      scope '/new-referee' do
        get '/' => 'additional_referees#show', as: :additional_referee
        get '/new' => 'additional_referees#new', as: :new_additional_referee
        post '/new' => 'additional_referees#create'

        get '/:application_reference_id/edit' => 'additional_referees#edit', as: :edit_additional_referee
        patch '/:application_reference_id/edit' => 'additional_referees#update'

        get '/confirm' => 'additional_referees#confirm', as: :confirm_additional_referees
        post '/confirm' => 'additional_referees#request_references'
      end

      scope '/equality-and-diversity' do
        get '/' => 'equality_and_diversity#start', as: :start_equality_and_diversity
        get '/sex' => 'equality_and_diversity#edit_sex', as: :edit_equality_and_diversity_sex
        post '/sex' => 'equality_and_diversity#update_sex', as: :update_equality_and_diversity_sex
        get '/disability-status' => 'equality_and_diversity#edit_disability_status', as: :edit_equality_and_diversity_disability_status
        post '/disability-status' => 'equality_and_diversity#update_disability_status', as: :update_equality_and_diversity_disability_status
        get '/disabilities' => 'equality_and_diversity#edit_disabilities', as: :edit_equality_and_diversity_disabilities
        post '/disabilities' => 'equality_and_diversity#update_disabilities', as: :update_equality_and_diversity_disabilities
        get '/ethnic-group' => 'equality_and_diversity#edit_ethnic_group', as: :edit_equality_and_diversity_ethnic_group
        post '/ethnic-group' => 'equality_and_diversity#update_ethnic_group', as: :update_equality_and_diversity_ethnic_group
        get '/ethnic-background' => 'equality_and_diversity#edit_ethnic_background', as: :edit_equality_and_diversity_ethnic_background
        post '/ethnic-background' => 'equality_and_diversity#update_ethnic_background', as: :update_equality_and_diversity_ethnic_background
        get '/review' => 'equality_and_diversity#review', as: :review_equality_and_diversity
      end
    end
  end

  namespace :referee_interface, path: '/reference' do
    get '/' => 'reference#feedback', as: :reference_feedback

    get '/confirmation' => 'reference#confirmation', as: :confirmation
    patch '/confirmation' => 'reference#submit_feedback', as: :submit_feedback

    patch '/questionnaire' => 'reference#submit_questionnaire', as: :submit_questionnaire
    get '/finish' => 'reference#finish', as: :finish

    get '/refuse-feedback' => 'reference#refuse_feedback', as: :refuse_feedback
    patch '/refuse-feedback' => 'reference#confirm_feedback_refusal'
  end

  namespace :vendor_api, path: 'api/v1' do
    get '/applications' => 'applications#index'
    get '/applications/:application_id' => 'applications#show'

    post '/applications/:application_id/offer' => 'decisions#make_offer'
    post '/applications/:application_id/confirm-conditions-met' => 'decisions#confirm_conditions_met'
    post '/applications/:application_id/conditions-not-met' => 'decisions#conditions_not_met'
    post '/applications/:application_id/reject' => 'decisions#reject'
    post '/applications/:application_id/confirm-enrolment' => 'decisions#confirm_enrolment'

    post '/test-data/regenerate' => 'test_data#regenerate'
    post '/experimental/test-data/generate' => 'test_data#generate'
    post '/experimental/test-data/clear' => 'test_data#clear!'

    get '/ping', to: 'ping#ping'
  end

  namespace :provider_interface, path: '/provider' do
    get '/' => 'start_page#show'

    get '/accessibility', to: 'content#accessibility'
    get '/privacy-policy', to: 'content#privacy_policy', as: :privacy_policy
    get '/cookies', to: 'content#cookies_provider', as: :cookies
    get '/terms-of-use', to: 'content#terms_provider', as: :terms

    get '/data-sharing-agreements/new', to: 'provider_agreements#new_data_sharing_agreement', as: :new_data_sharing_agreement
    post '/data-sharing-agreements', to: 'provider_agreements#create_data_sharing_agreement', as: :create_data_sharing_agreement
    get '/data-sharing-agreements/:id', to: 'provider_agreements#show_data_sharing_agreement', as: :show_data_sharing_agreement

    get '/applications' => 'application_choices#index'
    get '/applications/:application_choice_id' => 'application_choices#show', as: :application_choice
    get '/applications/:application_choice_id/respond' => 'decisions#respond', as: :application_choice_respond
    post '/applications/:application_choice_id/respond' => 'decisions#submit_response', as: :application_choice_submit_response
    get '/applications/:application_choice_id/offer' => 'decisions#new_offer', as: :application_choice_new_offer
    get '/applications/:application_choice_id/reject' => 'decisions#new_reject', as: :application_choice_new_reject
    post '/applications/:application_choice_id/reject/confirm' => 'decisions#confirm_reject', as: :application_choice_confirm_reject
    post '/applications/:application_choice_id/reject' => 'decisions#create_reject', as: :application_choice_create_reject
    post '/applications/:application_choice_id/offer/confirm' => 'decisions#confirm_offer', as: :application_choice_confirm_offer
    post '/applications/:application_choice_id/offer' => 'decisions#create_offer', as: :application_choice_create_offer
    get '/applications/:application_choice_id/conditions' => 'conditions#edit', as: :application_choice_edit_conditions
    patch '/applications/:application_choice_id/conditions/confirm' => 'conditions#confirm_update', as: :application_choice_confirm_update_conditions
    patch '/applications/:application_choice_id/conditions' => 'conditions#update', as: :application_choice_update_conditions
    get '/applications/:application_choice_id/edit_response' => 'decisions#new_edit_response', as: :application_choice_new_edit_response
    post '/applications/:application_choice_id/edit_response' => 'decisions#edit_response', as: :application_choice_edit_response
    get '/applications/:application_choice_id/offer/new_withdraw' => 'decisions#new_withdraw_offer', as: :application_choice_new_withdraw_offer
    post '/applications/:application_choice_id/offer/confirm_withdraw' => 'decisions#confirm_withdraw_offer', as: :application_choice_confirm_withdraw_offer
    post '/applications/:application_choice_id/offer/withdraw' => 'decisions#withdraw_offer', as: :application_choice_withdraw_offer

    post '/candidates/:candidate_id/impersonate' => 'candidates#impersonate', as: :impersonate_candidate

    get '/sign-in' => 'sessions#new'
    get '/sign-out' => 'sessions#destroy'
  end

  get '/auth/dfe/callback' => 'dfe_sign_in#callback'
  post '/auth/developer/callback' => 'dfe_sign_in#bypass_callback'

  namespace :integrations, path: '/integrations' do
    post '/notify/callback' => 'notify#callback'
    get '/feature-flags' => 'feature_flags#index'
    get '/performance-dashboard' => 'performance_dashboard#dashboard', as: :performance
  end

  namespace :support_interface, path: '/support' do
    get '/' => redirect('/support/candidates')

    get '/provider-flow', to: 'docs#provider_flow', as: :provider_flow
    get '/candidate-flow', to: 'docs#candidate_flow', as: :candidate_flow
    get '/when-emails-are-sent', to: 'docs#when_emails_are_sent', as: :when_emails_are_sent

    get '/email-log', to: 'email_log#index', as: :email_log

    get '/applications' => 'application_forms#index'
    get '/applications/:application_form_id' => 'application_forms#show', as: :application_form
    get '/applications/:application_form_id/audit' => 'application_forms#audit', as: :application_form_audit
    get '/applications/:application_form_id/comments/new' => 'application_forms/comments#new', as: :application_form_new_comment
    post '/applications/:application_form_id/comments' => 'application_forms/comments#create', as: :application_form_comments

    get '/candidates' => 'candidates#index'
    get '/candidates/:candidate_id' => 'candidates#show', as: :candidate
    post '/candidates/:candidate_id/hide' => 'candidates#hide_in_reporting', as: :hide_candidate
    post '/candidates/:candidate_id/show' => 'candidates#show_in_reporting', as: :show_candidate
    post '/candidates/:candidate_id/impersonate' => 'candidates#impersonate', as: :impersonate_candidate

    get '/send-survey-email/:application_form_id' => 'survey_emails#show', as: :survey_emails
    post '/send-survey-email/:application_form_id' => 'survey_emails#deliver'

    get '/tokens' => 'api_tokens#index', as: :api_tokens
    post '/tokens' => 'api_tokens#create'

    get '/providers' => 'providers#index', as: :providers
    post '/providers/sync' => 'providers#sync'
    get '/providers/:provider_id' => 'providers#show', as: :provider
    post '/providers/:provider_id' => 'providers#open_all_courses'
    post '/providers/:provider_id/enable_course_syncing' => 'providers#enable_course_syncing', as: :enable_provider_course_syncing

    get '/courses/:course_id' => 'courses#show', as: :course
    post '/courses/:course_id' => 'courses#update'

    get '/feature-flags' => 'feature_flags#index', as: :feature_flags
    post '/feature-flags/:feature_name/activate' => 'feature_flags#activate', as: :activate_feature_flag
    post '/feature-flags/:feature_name/deactivate' => 'feature_flags#deactivate', as: :deactivate_feature_flag

    get '/performance' => 'performance#index', as: :performance
    get '/performance/application-timings', to: 'performance#application_timings', as: :application_timings
    get '/performance/referee-survey', to: 'performance#referee_survey', as: :referee_survey

    get '/tasks' => 'tasks#index', as: :tasks
    post '/tasks/:task' => 'tasks#run', as: :run_task

    scope '/users' do
      get '/' => 'users#index', as: :users

      get '/delete/:id' => 'support_users#confirm_destroy', as: :confirm_destroy_support_user
      delete '/delete/:id' => 'support_users#destroy', as: :destroy_support_user

      resources :support_users, only: %i[index new create], path: :support
      resources :provider_users, only: %i[index new create edit update], path: :provider
    end

    get '/sign-in' => 'sessions#new'
    get '/sign-out' => 'sessions#destroy'

    # https://github.com/mperham/sidekiq/wiki/Monitoring#rails-http-basic-auth-from-routes
    require 'sidekiq/web'
    require 'support_user_constraint'

    mount Sidekiq::Web => '/sidekiq', constraints: SupportUserConstraint.new
    get '/sidekiq', to: redirect('/support/sign-in'), status: 302
  end

  namespace :api_docs, path: '/api-docs' do
    get '/' => 'pages#home', as: :home
    get '/usage-scenarios' => 'pages#usage', as: :usage
    get '/reference' => 'reference#reference', as: :reference
    get '/release-notes' => 'pages#release_notes', as: :release_notes
    get '/alpha-release-notes' => 'pages#alpha_release_notes'
    get '/lifecycle' => 'pages#lifecycle'
    get '/help' => 'pages#help', as: :help
    get '/spec.yml' => 'openapi#spec', as: :spec
  end

  get '/check', to: 'healthcheck#show'

  scope via: :all do
    match '/404', to: 'errors#not_found'
    match '/406', to: 'errors#not_acceptable'
    match '/422', to: 'errors#unprocessable_entity'
    match '/500', to: 'errors#internal_server_error'
  end

  get '*path', to: 'errors#not_found'
end
