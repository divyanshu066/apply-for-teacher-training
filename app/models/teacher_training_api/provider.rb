module TeacherTrainingAPI
  class Provider < TeacherTrainingAPI::Resource
    belongs_to :recruitment_cycle, param: :year
    has_many :courses

    def self.recruitment_cycle(year)
      where(recruitment_cycle_year: year)
    end
  end
end
