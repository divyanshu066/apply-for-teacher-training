module TeacherTrainingAPIHelper
  def stub_teacher_training_api_course(
    recruitment_cycle_year: RecruitmentCycle.current_year,
    provider_code:,
    course_code:,
    status: 200,
    specified_attributes: {}
  )
    # Make sure data returned is at least consistent with the URL
    if specified_attributes[:code].blank?
      specified_attributes[:code] = course_code
    end

    stub_request(:get, ENV.fetch('TEACHER_TRAINING_API_BASE_URL') +
      "recruitment_cycles/#{recruitment_cycle_year}" \
      "/providers/#{provider_code}" \
      "/courses/#{course_code}").to_return(
        status: status,
        headers: { 'Content-Type': 'application/vnd.api+json' },
        body: single_course_response(specified_attributes).to_json,
      )
  end

  def single_course_response(course_attrs = {})
    JSON.parse(
      File.read(
        Rails.root.join('spec/examples/teacher_training_api/course_single_response.json'),
      ),
      symbolize_names: true,
    ).tap do |api_response|
      api_response[:data][:attributes] = api_response[:data][:attributes].deep_merge(course_attrs)
    end
  end
end
