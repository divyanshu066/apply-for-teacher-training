require 'rails_helper'

RSpec.describe SupportInterface::ProviderCoursesTableComponent do
  describe 'course data' do
    it 'renders the correct data for a course' do
      course = create(:course,
                      name: 'My course',
                      code: 'ABC',
                      level: 'secondary',
                      recruitment_cycle_year: 2020,
                      exposed_in_find: true,
                      open_on_apply: true)

      course_option = create(:course_option, course: course)
      provider = course_option.course.provider

      render_result = render_inline(SupportInterface::ProviderCoursesTableComponent.new(provider: provider, courses: provider.courses))

      # Make a mapping colname -> colvalue
      fields = render_result.css('th').map(&:text).zip(
        render_result.css('td').map(&:text),
      ).to_h

      expect(fields['Course']).to eq('My course (ABC)')
      expect(fields['Cycle']).to eq('2020')
      expect(fields['Status']).to match(/Open on Apply/)
      expect(fields).not_to have_key('Accredited body')
    end

    it 'may include courses the provider accredits' do
      provider = create(:provider)
      other_course_provider = create(:provider, name: 'Other provider')

      create(:course_option, course: create(:course,
                                            provider: other_course_provider,
                                            accredited_provider: provider,
                                            name: 'Accredited course'))

      render_result = render_inline(SupportInterface::ProviderCoursesTableComponent.new(provider: provider, courses: provider.accredited_courses))

      expect(render_result.text).to include('Accredited course')
      expect(render_result.text).to include('Other provider')
    end

    it 'may include accredited providers' do
      accredited_provider = create(:provider, name: 'Accredited University', code: 'AU1')
      provider = create(:provider)

      course = create(
        :course,
        provider: provider,
        name: 'My course',
        code: 'ABC',
        level: 'secondary',
        recruitment_cycle_year: 2020,
        exposed_in_find: true,
        open_on_apply: true,
        accredited_provider: accredited_provider,
      )
      create(:course_option, course: course)

      render_result = render_inline(SupportInterface::ProviderCoursesTableComponent.new(provider: provider, courses: provider.courses))

      # Make a mapping colname -> colvalue
      fields = render_result.css('th').map(&:text).zip(
        render_result.css('td').map(&:text),
      ).to_h

      expect(fields['Course']).to eq('My course (ABC)')
      expect(fields['Cycle']).to eq('2020')
      expect(fields).to have_key('Accredited body')
      expect(fields['Accredited body']).to match(/Accredited University \(AU1\)/)
    end
  end
end
