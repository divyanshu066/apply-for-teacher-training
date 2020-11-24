module TeacherTrainingAPI
  class Provider < TeacherTrainingAPI::Resource
    belongs_to :recruitment_cycle, param: :recruitment_cycle_year
    has_many :courses
    has_many :sites

    # There's a quirk in the JsonAPIClient that means we have to do some
    # counter-intuitive things with our resource models to get it to work.
    # In this case, to get included course subjects to work, we have to define
    # this as an inner class of Provider, despite it actually being a has-has_many
    # of Course. Do not know why - if anyone can figure out a more
    # elegant way, feel free.
    class Subject < TeacherTrainingAPI::Resource; end

    def self.recruitment_cycle(year)
      where(recruitment_cycle_year: year)
    end
  end
end
