desc 'Reset the QA database and populate it with providers, dummy applications and whitelisted support/provider users'
task reset_qa: %i[environment db:reset sync_dev_providers_and_open_courses generate_test_applications] do
  SetupQAEnvironment.call
end
