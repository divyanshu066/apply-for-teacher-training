require 'rails_helper'

RSpec.describe UCASMatch do
  let(:candidate) { create(:candidate) }
  let(:course) { create(:course) }
  let!(:application_form_awaiting_provider_decision) { create(:completed_application_form, candidate_id: candidate.id, application_choices_count: 1) }
  let(:course1) { application_form_awaiting_provider_decision.application_choices.first.course_option.course }

  describe '#action_needed?' do
    it 'returns false if initial emails were sent and we do not need to send the reminders yet' do
      initial_emails_sent_at = Time.zone.now
      ucas_match = create(:ucas_match, matching_state: 'new_match', action_taken: 'initial_emails_sent', candidate_last_contacted_at: initial_emails_sent_at)
      allow(ucas_match).to receive(:dual_application_or_dual_acceptance?).and_return(true)

      Timecop.travel(1.business_days.after(initial_emails_sent_at)) do
        expect(ucas_match.action_needed?).to eq(false)
      end
    end

    it 'returns true if initial emails were sent and it is time to send reminder emails' do
      initial_emails_sent_at = Time.zone.now
      ucas_match = create(:ucas_match, matching_state: 'new_match', action_taken: 'initial_emails_sent', candidate_last_contacted_at: initial_emails_sent_at)
      allow(ucas_match).to receive(:dual_application_or_dual_acceptance?).and_return(true)

      Timecop.travel(5.business_days.after(initial_emails_sent_at)) do
        expect(ucas_match.action_needed?).to eq(true)
      end
    end

    it 'returns false if reminder emails were sent and we do not need to request withdrawal from UCAS yet' do
      ucas_match = create(:ucas_match, matching_state: 'new_match', action_taken: 'reminder_emails_sent', candidate_last_contacted_at: Time.zone.now)
      allow(ucas_match).to receive(:dual_application_or_dual_acceptance?).and_return(true)
      allow(ucas_match).to receive(:need_to_request_withdrawal_from_ucas?).and_return(false)

      expect(ucas_match.action_needed?).to eq(false)
    end

    it 'returns true if reminder emails were sent and it is time to request withdrawal from UCAS' do
      ucas_match = create(:ucas_match, matching_state: 'new_match', action_taken: 'reminder_emails_sent', candidate_last_contacted_at: Time.zone.now)
      allow(ucas_match).to receive(:dual_application_or_dual_acceptance?).and_return(true)
      allow(ucas_match).to receive(:need_to_request_withdrawal_from_ucas?).and_return(true)

      expect(ucas_match.action_needed?).to eq(true)
    end

    it 'returns true if we requested withdrawal from UCAS' do
      ucas_match = create(:ucas_match, matching_state: 'new_match', action_taken: 'ucas_withdrawal_requested', candidate_last_contacted_at: Time.zone.now)
      allow(ucas_match).to receive(:dual_application_or_dual_acceptance?).and_return(true)

      expect(ucas_match.action_needed?).to eq(false)
    end

    it 'returns true if there is a dual application or dual acceptance' do
      ucas_match = create(:ucas_match, matching_state: 'new_match')
      allow(ucas_match).to receive(:dual_application_or_dual_acceptance?).and_return(true)

      expect(ucas_match.action_needed?).to eq(true)
    end

    it 'returns false if there is no dual application or dual acceptance' do
      ucas_match = create(:ucas_match, matching_state: 'new_match')
      allow(ucas_match).to receive(:dual_application_or_dual_acceptance?).and_return(false)

      expect(ucas_match.action_needed?).to eq(false)
    end
  end

  describe '#dual_application_or_dual_acceptance?' do
    it 'returns true if a candidate applied for the same course on both services and both applications are still in progress' do
      ucas_matching_data = { 'Scheme' => 'B',
                             'Course code' => course1.code.to_s,
                             'Provider code' => course1.provider.code.to_s,
                             'Apply candidate ID' => candidate.id.to_s }
      ucas_match = create(:ucas_match, matching_state: 'new_match', candidate: candidate, matching_data: [ucas_matching_data])

      expect(ucas_match.dual_application_or_dual_acceptance?).to eq(true)
    end

    it 'returns false if a candidate applied for the same course on both services but at least one of them was unsucesfull' do
      ucas_matching_data = { 'Scheme' => 'B',
                             'Course code' => course1.code.to_s,
                             'Provider code' => course1.provider.code.to_s,
                             'Apply candidate ID' => candidate.id.to_s,
                             'Rejects' => '1' }
      ucas_match = create(:ucas_match, matching_state: 'new_match', candidate: candidate, matching_data: [ucas_matching_data])

      expect(ucas_match.dual_application_or_dual_acceptance?).to eq(false)
    end

    it 'returns true if application is accepted on UCAS and accepted on Apply' do
      application_choice = create(:application_choice, :with_accepted_offer)
      create(:completed_application_form, candidate_id: candidate.id, application_choices: [application_choice])
      course1 = application_choice.course_option.course
      ucas_matching_data = { 'Scheme' => 'U',
                             'Offers' => '1',
                             'Conditional firm' => '1',
                             'Provider code' => course.provider.code.to_s }
      apply_matching_data = { 'Scheme' => 'D',
                              'Course code' => course1.code.to_s,
                              'Provider code' => course1.provider.code.to_s,
                              'Apply candidate ID' => candidate.id.to_s }
      ucas_match = create(:ucas_match, matching_state: 'new_match', candidate: candidate, matching_data: [ucas_matching_data, apply_matching_data])

      expect(ucas_match.dual_application_or_dual_acceptance?).to eq(true)
    end

    it 'returns false if applications on both services are in unsucesfull states' do
      application_choice = create(:application_choice, :with_rejection)
      create(:completed_application_form, candidate_id: candidate.id, application_choices: [application_choice])
      course1 = application_choice.course_option.course
      ucas_matching_data = { 'Scheme' => 'U',
                             'Withdraws' => '1',
                             'Provider code' => course.provider.code.to_s }
      apply_matching_data = { 'Scheme' => 'D',
                              'Course code' => course1.code.to_s,
                              'Provider code' => course1.provider.code.to_s,
                              'Apply candidate ID' => candidate.id.to_s }
      ucas_match = create(:ucas_match, matching_state: 'new_match', candidate: candidate, matching_data: [ucas_matching_data, apply_matching_data])

      expect(ucas_match.dual_application_or_dual_acceptance?).to eq(false)
    end

    it 'returns false if applications on both services are in progress' do
      course1 = application_form_awaiting_provider_decision.application_choices.first.course_option.course
      ucas_matching_data = { 'Scheme' => 'U',
                             'Provider code' => course.provider.code.to_s }
      apply_matching_data = { 'Scheme' => 'D',
                              'Course code' => course1.code.to_s,
                              'Provider code' => course1.provider.code.to_s,
                              'Apply candidate ID' => candidate.id.to_s }
      ucas_match = create(:ucas_match, matching_state: 'new_match', candidate: candidate, matching_data: [ucas_matching_data, apply_matching_data])

      expect(ucas_match.dual_application_or_dual_acceptance?).to eq(false)
    end
  end

  describe '#need_to_send_reminder_emails?' do
    it 'returns false if last action taken in not initial emails sent' do
      emails_sent_at = Time.zone.now
      ucas_match = create(:ucas_match, matching_state: 'new_match', action_taken: 'ucas_withdrawal_requested', candidate_last_contacted_at: emails_sent_at)

      Timecop.travel(1.business_days.after(emails_sent_at)) do
        expect(ucas_match.need_to_send_reminder_emails?).to eq(false)
      end
    end

    it 'returns false if initial emails were sent and we do not need to send the reminders yet' do
      emails_sent_at = Time.zone.now
      ucas_match = create(:ucas_match, matching_state: 'new_match', action_taken: 'initial_emails_sent', candidate_last_contacted_at: emails_sent_at)

      Timecop.travel(1.business_days.after(emails_sent_at)) do
        expect(ucas_match.need_to_send_reminder_emails?).to eq(false)
      end
    end

    it 'returns true if initial emails were sent and it is time to send reminder emails' do
      emails_sent_at = Time.zone.now
      ucas_match = create(:ucas_match, matching_state: 'new_match', action_taken: 'initial_emails_sent', candidate_last_contacted_at: emails_sent_at)

      Timecop.travel(5.business_days.after(emails_sent_at)) do
        expect(ucas_match.need_to_send_reminder_emails?).to eq(true)
      end
    end
  end

  describe '#need_to_request_withdrawal_from_ucas?' do
    it 'returns false if last action taken in not reminder emails sent' do
      emails_sent_at = Time.zone.now
      ucas_match = create(:ucas_match, matching_state: 'new_match', action_taken: 'ucas_withdrawal_requested', candidate_last_contacted_at: emails_sent_at)

      Timecop.travel(1.business_days.after(emails_sent_at)) do
        expect(ucas_match.need_to_request_withdrawal_from_ucas?).to eq(false)
      end
    end

    it 'returns false if reminder emails were sent and we do not need to request withdrawal from ucas yet' do
      emails_sent_at = Time.zone.now
      ucas_match = create(:ucas_match, matching_state: 'new_match', action_taken: 'reminder_emails_sent', candidate_last_contacted_at: emails_sent_at)

      Timecop.travel(1.business_days.after(emails_sent_at)) do
        expect(ucas_match.need_to_request_withdrawal_from_ucas?).to eq(false)
      end
    end

    it 'returns true if reminder emails were sent and it is time to request withdrawal from ucas' do
      emails_sent_at = Time.zone.now
      ucas_match = create(:ucas_match, matching_state: 'new_match', action_taken: 'reminder_emails_sent', candidate_last_contacted_at: emails_sent_at)

      Timecop.travel(10.business_days.after(emails_sent_at)) do
        expect(ucas_match.need_to_request_withdrawal_from_ucas?).to eq(true)
      end
    end
  end

  describe '#next_action' do
    it 'returns :initial_emails_sent if the candidate has never been contacted' do
      ucas_match = create(:ucas_match, matching_state: 'new_match')

      expect(ucas_match.next_action).to eq(:initial_emails_sent)
    end

    it 'returns :reminder_emails_sent if initial emails were sent and it time to send reminder emails' do
      ucas_match = create(:ucas_match, matching_state: 'new_match', action_taken: 'initial_emails_sent', candidate_last_contacted_at: Time.zone.now - 6.days)
      allow(ucas_match).to receive(:need_to_send_reminder_emails?).and_return(true)

      expect(ucas_match.next_action).to eq(:reminder_emails_sent)
    end

    it 'returns :ucas_withdrawal_requested if reminder emails were sent and it time to request withdrawal from UCAS' do
      ucas_match = create(:ucas_match, matching_state: 'new_match', action_taken: 'reminder_emails_sent', candidate_last_contacted_at: Time.zone.now - 16.days)
      allow(ucas_match).to receive(:need_to_request_withdrawal_from_ucas?).and_return(true)

      expect(ucas_match.next_action).to eq(:ucas_withdrawal_requested)
    end

    it 'returns nil if withdrawal from UCAS was requested' do
      ucas_match = create(:ucas_match, matching_state: 'new_match', action_taken: 'ucas_withdrawal_requested', candidate_last_contacted_at: Time.zone.now)

      expect(ucas_match.next_action).to eq(nil)
    end
  end

  describe '#last_action' do
    it 'returns nil if no action was taken' do
      ucas_match = create(:ucas_match, matching_state: 'new_match')

      expect(ucas_match.last_action).to eq(nil)
    end

    it 'returns :initial_emails_sent if initial emails were sent' do
      ucas_match = create(:ucas_match, matching_state: 'new_match', action_taken: 'initial_emails_sent')

      expect(ucas_match.last_action).to eq(:initial_emails_sent)
    end

    it 'returns :reminder_emails_sent if reminder emails were sent' do
      ucas_match = create(:ucas_match, matching_state: 'new_match', action_taken: 'reminder_emails_sent')

      expect(ucas_match.last_action).to eq(:reminder_emails_sent)
    end

    it 'returns :ucas_withdrawal_requested if ucas withdrawal was requested' do
      ucas_match = create(:ucas_match, matching_state: 'new_match', action_taken: 'ucas_withdrawal_requested')

      expect(ucas_match.last_action).to eq(:ucas_withdrawal_requested)
    end
  end
end
