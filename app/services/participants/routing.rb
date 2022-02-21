# frozen_string_literal: true

module Participants
  class Routing
    def call(mapper, _options = {})
      mapper.member { mapper.put :withdraw }
      mapper.member { mapper.put :defer }
      mapper.member { mapper.put :resume }
      mapper.member { mapper.put :change_schedule, path: "change-schedule" }
    end
  end
end
