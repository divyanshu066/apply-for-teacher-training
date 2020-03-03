class SetupQAEnvironment
  def self.call
    raise 'You can’t do this anywhere but QA or development!' unless %w[qa development].include?(HostingEnvironment.environment_name)

    # uids_url = 'https://gist.githubusercontent.com/duncanjbrown/7bd78a04c1faab0f8d2525ad7189e33f/raw/a839a3c21ad02ecdde8691eb52db02c0d099f154/uids'
    uids_url = ENV['QA_USER_UIDS_URL']
    uids_response = Net::HTTP.get_response(URI.parse(uids_url))

    if uids_response.is_a? Net::HTTPSuccess
      uids = uids_response.body.split("\n")
    else
      raise "Could not load the UIDs file at #{uids_url}. Received status code #{uids_response.code}"
    end

    raise "No UIDs found in the UIDs file at #{uids_url}" unless uids.any?

    provider = ApplicationChoice.first.provider
    uids.each do |uid|
      email = Faker::Internet.email
      SupportUser.create!(dfe_sign_in_uid: uid, email_address: email)
      ProviderUser.create!(providers: [provider], dfe_sign_in_uid: uid, email_address: email)
    end
  end
end
