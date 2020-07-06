module CandidateInterface
  class DegreeGradeForm
    include ActiveModel::Model

    attr_accessor :grade, :other_grade, :predicted_grade, :degree

    validates :grade, presence: true
    validates :other_grade, presence: true, if: :other_grade?
    validates :predicted_grade, presence: true, if: :predicted_grade?

    validates :grade, :other_grade, :predicted_grade, length: { maximum: 255 }

    def save
      return false unless valid?

      submitted_grade = determine_submitted_grade
      hesa_code = Hesa::Grade.find_by_description(submitted_grade)&.hesa_code

      degree.update!(
        grade: determine_submitted_grade,
        predicted_grade: grade == 'predicted',
        grade_hesa_code: hesa_code,
      )
    end

    def fill_form_values
      FeatureFlag.active?(:hesa_degree_data) ? fill_hesa_form : fill_non_hesa_form

      self
    end

  private

    def fill_hesa_form
      if degree.predicted_grade?
        self.grade = 'predicted'
        self.predicted_grade = degree.grade
      elsif degree.grade_hesa_code.present?
        hesa_grade = Hesa::Grade.find_by_hesa_code(degree.grade_hesa_code)
        if hesa_grade.visual_grouping == :other
          self.grade = 'other'
          self.other_grade = hesa_grade.description
        else
          self.grade = hesa_grade.description
        end
      else
        self.grade = 'other'
        self.other_grade = degree.grade
      end
    end

    def fill_non_hesa_form
      if degree.predicted_grade?
        self.grade = 'predicted'
        self.predicted_grade = degree.grade
      elsif degree.grade.in? %w[first upper_second lower_second third]
        self.grade = degree.grade
      else
        self.grade = 'other'
        self.other_grade = degree.grade
      end
    end

    def other_grade?
      grade == 'other'
    end

    def predicted_grade?
      grade == 'predicted'
    end

    def determine_submitted_grade
      case grade
      when 'other'
        other_grade
      when 'predicted'
        predicted_grade
      else
        grade
      end
    end
  end
end