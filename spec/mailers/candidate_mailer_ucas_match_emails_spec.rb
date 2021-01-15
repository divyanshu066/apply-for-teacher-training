require 'rails_helper'

RSpec.describe CandidateMailer, type: :mailer do
  subject(:mailer) { described_class }

  let(:application_form) { build_stubbed(:application_form, first_name: 'Ada', last_name: 'Lovelace', application_choices: application_choices) }
  let(:course) { build_stubbed(:course, name: 'Primary', code: '33WA', provider: provider) }
  let(:course_option) { build_stubbed(:course_option, course: course) }
  let(:provider) { build_stubbed(:provider, name: 'Wonderland University') }
  let(:application_choice) { build_stubbed(:application_choice, course_option: course_option, offered_course_option: course_option) }
  let(:application_choices) { [application_choice] }

  describe '.ucas_match_resolved_on_ucas_email' do
    let(:email) { mailer.ucas_match_resolved_on_ucas_email(application_form.application_choices.first) }

    it_behaves_like(
      'a mail with subject and content',
      I18n.t!('candidate_mailer.ucas_match.resolved_on_ucas.subject'),
      'heading' => 'Dear Ada Lovelace',
      'course_code_and_option' => 'to study Primary (33WA) at Wonderland University',
      'tracking' => 'use Apply for teacher training',
      'removal details' => 'the course choice was removed from your UCAS application',
    )
  end

  describe '.ucas_match_resolved_on_apply_email' do
    let(:email) { mailer.ucas_match_resolved_on_apply_email(application_form.application_choices.first) }

    it_behaves_like(
      'a mail with subject and content',
      I18n.t!('candidate_mailer.ucas_match.resolved_on_apply.subject'),
      'heading' => 'Dear Ada Lovelace',
      'course_code_and_option' => 'to study Primary (33WA) at Wonderland University',
      'tracking' => 'use [UCAS Teacher Training]',
      'removal details' => 'the course choice was removed from your DfE Apply application',
    )
  end
end
