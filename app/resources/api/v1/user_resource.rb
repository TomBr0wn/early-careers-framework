# frozen_string_literal: true

module Api
  module V1
    class UserResource < JSONAPI::Resource
      has_many :npq_profiles
    end
  end
end
