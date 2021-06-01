# frozen_string_literal: true

class ApiToken < ApplicationRecord
  self.abstract_class = true

  def self.create_with_random_token!(**options)
    unhashed_token, hashed_token = Devise.token_generator.generate(ApiToken, :hashed_token)
    create!(hashed_token: hashed_token, **options)
    unhashed_token
  end

  def self.find_by_unhashed_token(unhashed_token)
    hashed_token = Devise.token_generator.digest(ApiToken, :hashed_token, unhashed_token)
    find_by(hashed_token: hashed_token)
  end

  def owner
    raise NotImplementedError
  end
end
