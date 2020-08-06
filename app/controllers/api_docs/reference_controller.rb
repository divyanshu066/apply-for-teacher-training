module APIDocs
  class ReferenceController < APIDocsController
    def reference
      @api_reference = GovukOpenapiReference::HTML.new(VendorAPISpecification.as_hash)
    end
  end
end
