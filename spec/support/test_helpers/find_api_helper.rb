module FindAPIHelper
  def stubbed_recruitment_cycle_year
    @stubbed_recruitment_cycle_year || 2021
  end

  def stub_find_api_provider_200(
    provider_code: 'ABC',
    provider_name: 'Dummy Provider',
    postcode: 'SW1P 3BT',
    provider_type: 'scitt',
    course_code: 'X130',
    site_code: 'X',
    findable: true,
    study_mode: 'full_time',
    description: 'PGCE with QTS full time',
    start_date: Time.zone.local(stubbed_recruitment_cycle_year, 10, 31),
    course_length: 'OneYear',
    region_code: 'north_west',
    site_address_line2: 'C/O The Bruntcliffe Academy',
    funding_type: 'fee',
    age_range_in_years: '4 to 8',
    vac_status: 'full_time_vacancies',
    content_status: 'published',
    latitude: '51.498024',
    longitude: '0.129919'
  )
    stub_find_api_provider(provider_code)
      .to_return(
        status: 200,
        headers: { 'Content-Type': 'application/vnd.api+json' },
        body: {
          'data': {
            'id': '1',
            'type': 'providers',
            'attributes': {
              'provider_name': provider_name,
              'provider_code': provider_code,
              'region_code': region_code,
              'postcode': postcode,
              'latitude': latitude,
              'longitude': longitude,
            },
            'relationships': {
              'sites': {
                'data': [
                  { 'id': '1', 'type': 'sites' },
                ],
              },
              'courses': {
                'data': [
                  { 'id': '1', 'type': 'courses' },
                ],
              },
            },
          },
          'included': [
            {
              'id': '1',
              'type': 'sites',
              'attributes': {
                'code': site_code,
                'location_name': 'Main site',
                'address1': 'Gorse SCITT ',
                'address2': site_address_line2,
                'address3': 'Bruntcliffe Lane',
                'address4': 'MORLEY, LEEDS',
                'postcode': 'LS27 0LZ',
                'longitude': -1.620208,
                'latitude': 53.745587,
              },
            },
            {
              'id': '1',
              'type': 'courses',
              'attributes': {
                'course_code': course_code,
                'name': 'Primary',
                'level': 'primary',
                'study_mode': study_mode,
                'description': description,
                'start_date': start_date,
                'course_length': course_length,
                'recruitment_cycle_year': stubbed_recruitment_cycle_year.to_s,
                'findable?': findable,
                'accrediting_provider': nil,
                'funding_type': funding_type,
                'age_range_in_years': age_range_in_years,
                'content_status': content_status,
                'provider_type': provider_type,
              },
              'relationships': {
                'sites': {
                  'data': [
                    { 'id': '1', 'type': 'sites' },
                  ],
                },
                'subjects': {
                  'data': [
                    { 'type': 'subjects', 'id': '11' },
                  ],
                },
                'site_statuses': {
                  'data': [
                    { 'id': '222', 'type': 'site_statuses' },
                  ],
                },
              },
            },
            {
              'id': '222',
              'type': 'site_statuses',
              'attributes': {
                'vac_status': vac_status,
                'publish': 'published',
                'status': 'running',
                'has_vacancies?': true,
              },
              'relationships': {
                'site': {
                  'data': {
                    'type': 'sites',
                    'id': '1',
                  },
                },
              },
            },
            {
              'id': '11',
              'type': 'subjects',
              'attributes': {
                'subject_name': 'Business studies',
                'subject_code': '08',
                'bursary_amount': '9000',
                'early_career_payments': nil,
                'scholarship': nil,
                'subject_knowledge_enhancement_course_available': false,
              },
            },
          ],
          'jsonapi': { 'version': '1.0' },
        }.to_json,
      )
  end

  def stub_find_api_provider_200_with_accredited_provider(
    provider_code: 'ABC',
    provider_name: 'Dummy Provider',
    postcode: 'SW1P 3BT',
    provider_type: 'scitt',
    course_code: 'X130',
    site_code: 'X',
    accredited_provider_code: 'XYZ',
    accredited_provider_name: 'Dummy Accredited Provider',
    findable: true,
    study_mode: 'full_time',
    description: 'PGCE with QTS full time',
    start_date: Time.zone.local(stubbed_recruitment_cycle_year, 10, 31),
    course_length: 'OneYear',
    region_code: 'north_west',
    age_range_in_years: '4 to 8',
    content_status: 'published',
    latitude: '51.498024',
    longitude: '0.129919'
  )
    stub_find_api_provider(provider_code)
      .to_return(
        status: 200,
        headers: { 'Content-Type': 'application/vnd.api+json' },
        body: {
          'data': {
            'id': '1',
            'type': 'providers',
            'attributes': {
              'provider_name': provider_name,
              'provider_code': provider_code,
              'region_code': region_code,
              'postcode': postcode,
              'latitude': latitude,
              'longitude': longitude,
            },
            'relationships': {
              'sites': {
                'data': [
                  { 'id': '1', 'type': 'sites' },
                ],
              },
              'courses': {
                'data': [
                  { 'id': '1', 'type': 'courses' },
                ],
              },
            },
          },
          'included': [
            {
              'id': '1',
              'type': 'sites',
              'attributes': {
                'code': site_code,
                'location_name': 'Main site',
                'address1': 'Gorse SCITT',
                'address2': 'C/O The Bruntcliffe Academy',
                'address3': 'Bruntcliffe Lane',
                'address4': 'MORLEY, LEEDS',
                'postcode': 'LS27 0LZ',
                'longitude': -1.620208,
                'latitude': 53.745587,
              },
            },
            {
              'id': '1',
              'type': 'courses',
              'attributes': {
                'course_code': course_code,
                'name': 'Primary',
                'level': 'primary',
                'study_mode': study_mode,
                'description': description,
                'start_date': start_date,
                'course_length': course_length,
                'recruitment_cycle_year': stubbed_recruitment_cycle_year.to_s,
                'findable?': findable,
                'content_status': content_status,
                'accrediting_provider': {
                  'provider_name': accredited_provider_name,
                  'provider_code': accredited_provider_code,
                },
                'funding_type': 'fee',
                'age_range_in_years': age_range_in_years,
                'provider_type': provider_type,
              },
              'relationships': {
                'sites': {
                  'data': [
                    { 'id': '1', 'type': 'sites' },
                  ],
                },
                'subjects': {
                  'data': [
                    { 'type': 'subjects', 'id': '11' },
                  ],
                },
                'site_statuses': {
                  'data': [
                    { 'id': '222', 'type': 'site_statuses' },
                  ],
                },
              },
            },
            {
              'id': '222',
              'type': 'site_statuses',
              'attributes': {
                'vac_status': 'full_time_vacancies',
                'publish': 'published',
                'status': 'running',
                'has_vacancies?': true,
              },
              'relationships': {
                'site': {
                  'data': {
                    'type': 'sites',
                    'id': '1',
                  },
                },
              },
            },
          ],
          'jsonapi': { 'version': '1.0' },
        }.to_json,
      )
  end

  def stub_find_api_all_providers_200(provider_data)
    data = provider_data.each_with_index.map do |attributes, index|
      {
        id: index.to_s,
        type: 'providers',
        attributes: {
          provider_code: attributes[:provider_code],
          provider_name: attributes[:name],
          recruitment_cycle_year: stubbed_recruitment_cycle_year.to_s,
        },
        relationships: {
          courses: {
            meta: {
              count: 1,
            },
          },
        },
      }
    end

    stub_find_api_all_providers
      .to_return(
        status: 200,
        headers: { 'Content-Type': 'application/vnd.api+json' },
        body: {
          data: data,
          jsonapi: { version: '1.0' },
        }.to_json,
      )
  end

  def stub_find_api_course_200(provider_code, course_code, course_name)
    stub_find_api_course(provider_code, course_code)
      .to_return(
        status: 200,
        headers: { 'Content-Type': 'application/vnd.api+json' },
        body: {
          'data' => {
            'id' => '1',
            'type' => 'courses',
            'attributes' => {
              'course_code' => course_code,
              'name' => course_name,
              'provider_code' => provider_code,
            },
            'relationships': {
              'sites': {
                'data': [
                  { 'id': '1', 'type': 'sites' },
                ],
              },
            },
          },
          'included': [
            {
              'id': '1',
              'type': 'sites',
              'attributes': {
                'code': 'A',
                'location_name': 'Main site',
                'address1': 'Gorse SCITT ',
                'address2': '',
                'address3': 'Bruntcliffe Lane',
                'address4': 'MORLEY, LEEDS',
                'postcode': 'LS27 0LZ',
                'longitude': -1.620208,
                'latitude': 53.745587,
              },
            },
          ],
          'jsonapi' => { 'version' => '1.0' },
        }.to_json,
      )
  end

  def stub_find_api_course_timeout(provider_code, course_code)
    stub_find_api_course(provider_code, course_code)
      .to_timeout
  end

  def stub_find_api_course_404(provider_code, course_code)
    stub_find_api_course(provider_code, course_code)
      .to_return(status: 404)
  end

  def stub_find_api_course_503(provider_code, course_code)
    stub_find_api_course(provider_code, course_code)
      .to_return(status: 503)
  end

  def stub_find_api_course(provider_code, course_code)
    stub_request(
      :get, ENV.fetch('FIND_BASE_URL') +
      "recruitment_cycles/#{stubbed_recruitment_cycle_year}" \
      "/providers/#{provider_code}" \
      "/courses/#{course_code}" \
      '?include=sites'
    )
  end

  def stub_find_api_provider_200_with_subject_codes(
    provider_code: 'ABC',
    provider_name: 'Dummy Provider',
    postcode: 'SW1P 3BT',
    provider_type: 'scitt',
    course_code: 'X130',
    site_code: 'X',
    findable: true,
    study_mode: 'full_time',
    description: 'PGCE with QTS full time',
    start_date: Time.zone.local(stubbed_recruitment_cycle_year, 10, 31),
    course_length: 'OneYear',
    region_code: 'north_west',
    site_address_line2: 'C/O The Bruntcliffe Academy',
    funding_type: 'fee',
    age_range_in_years: '4 to 8',
    vac_status: 'full_time_vacancies',
    qualifications: %w[PG PF],
    program_type: 'SD',
    content_status: 'published',
    latitude: '51.498024',
    longitude: '0.129919'
  )
    stub_find_api_provider(provider_code)
      .to_return(
        status: 200,
        headers: { 'Content-Type': 'application/vnd.api+json' },
        body: {
          'data': {
            'id': '1',
            'type': 'providers',
            'attributes': {
              'provider_name': provider_name,
              'provider_code': provider_code,
              'region_code': region_code,
              'postcode': postcode,
              'latitude': latitude,
              'longitude': longitude,
            },
            'relationships': {
              'sites': {
                'data': [
                  { 'id': '1', 'type': 'sites' },
                ],
              },
              'courses': {
                'data': [
                  { 'id': '1', 'type': 'courses' },
                ],
              },
            },
          },
          'included': [
            {
              'id': '1',
              'type': 'sites',
              'attributes': {
                'code': site_code,
                'location_name': 'Main site',
                'address1': 'Gorse SCITT ',
                'address2': site_address_line2,
                'address3': 'Bruntcliffe Lane',
                'address4': 'MORLEY, LEEDS',
                'postcode': 'LS27 0LZ',
                'longitude': -1.620208,
                'latitude': 53.745587,
              },
            },
            {
              'id': '1',
              'type': 'courses',
              'attributes': {
                'course_code': course_code,
                'name': 'Primary',
                'level': 'primary',
                'study_mode': study_mode,
                'description': description,
                'start_date': start_date,
                'course_length': course_length,
                'recruitment_cycle_year': stubbed_recruitment_cycle_year.to_s,
                'findable?': findable,
                'accrediting_provider': nil,
                'funding_type': funding_type,
                'age_range_in_years': age_range_in_years,
                'program_type': program_type,
                'qualifications': qualifications,
                'content_status': content_status,
                'provider_type': provider_type,
              },
              'relationships': {
                'sites': {
                  'data': [
                    { 'id': '1', 'type': 'sites' },
                  ],
                },
                'subjects': {
                  'data': [
                    { 'type': 'subjects', 'id': '11' },
                  ],
                },
                'site_statuses': {
                  'data': [
                    { 'id': '222', 'type': 'site_statuses' },
                  ],
                },
              },
            },
            {
              'id': '222',
              'type': 'site_statuses',
              'attributes': {
                'vac_status': vac_status,
                'publish': 'published',
                'status': 'running',
                'has_vacancies?': true,
              },
              'relationships': {
                'site': {
                  'data': {
                    'type': 'sites',
                    'id': '1',
                  },
                },
              },
            },
            {
              'id': '11',
              'type': 'subjects',
              'attributes': {
                'subject_name': 'Business studies',
                'subject_code': '08',
                'bursary_amount': '9000',
                'early_career_payments': nil,
                'scholarship': nil,
                'subject_knowledge_enhancement_course_available': false,
              },
            },
          ],
          'jsonapi': { 'version': '1.0' },
        }.to_json,
      )
  end

private

  def stub_find_api_all_providers
    stub_request(
      :get,
      "#{ENV.fetch('FIND_BASE_URL')}recruitment_cycles/#{stubbed_recruitment_cycle_year}/providers",
    )
  end

  def stub_find_api_provider(provider_code)
    stub_request(:get, ENV.fetch('FIND_BASE_URL') +
      "recruitment_cycles/#{stubbed_recruitment_cycle_year}" \
      "/providers/#{provider_code}?include=courses.subjects")
  end
end
