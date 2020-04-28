Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    # should be VendorAPIUser, maintained for backwards compat with the audit log
    'vendor_api_user' => 'VendorApiUser',
  )
end
