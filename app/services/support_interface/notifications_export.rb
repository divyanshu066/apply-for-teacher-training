module SupportInterface
  class NotificationsExport
    def data_for_export
      providers = Provider.all.includes(:provider_users, :application_choices)
      providers.flat_map do |provider|
        data_for_provider(provider, provider_users_with_make_decisions(provider), visible_applications(provider))
      end
    end

  private

    def data_for_provider(provider, users_with_make_decisions, applications)
      {
          'Provider Code' => provider.code,
          'Provider' => provider.name,
          'No. Applications Received' => applications.count,
          'No. Applications awaiting decisions' => applications.where(status: :awaiting_provider_decision).count,
          'No. applications receiving decisions' => applications.where(status: ApplicationStateChange::STATES_VISIBLE_TO_PROVIDER - ApplicationStateChange::DECISION_PENDING_STATUSES).count - applications.where(status: :rejected, rejected_by_default: true).count,
          "No. applications RBD'd" => applications.where(status: :rejected, rejected_by_default: true).count,
          'No. provider users' => provider.provider_users.count,
          'No. users with make_decisions' => users_with_make_decisions.count,
          'No. of users with make_decisions and notifications disabled' => users_with_make_decisions.count(&:send_notifications),
          'No. of users with make_decisions and notifications enabled' => users_with_make_decisions.count {|u| !u.send_notifications },
      }
    end

    def provider_users_with_make_decisions(provider)
      provider.provider_permissions.includes(:provider_user).where(make_decisions: true).map(&:provider_user)
    end

    def visible_applications(provider)
      provider.application_choices.where(status: ApplicationStateChange::STATES_VISIBLE_TO_PROVIDER)
    end
  end
end

