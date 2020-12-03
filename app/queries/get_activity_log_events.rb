class GetActivityLogEvents
  def self.call(application_choices:, since: nil)
    since ||= Time.zone.local(2018, 1, 1) # before the pilot began, i.e. all records

    Audited::Audit.includes(:auditable)
      .where(auditable: application_choices)
      .where(action: :update)
      .where('created_at > ?', since)
      .order(created_at: :desc)
  end
end
