# frozen_string_literal: true

FactoryBot.define do
  factory :school do
    urn { Faker::Number.unique.decimal_part(digits: 7).to_s }
    name  { Faker::University.name }
    country { "England" }
    postcode { Faker::Address.postcode }
    address_line1 { Faker::Address.street_address }
    domains { [Faker::Internet.domain_name] }
    local_authority
    local_authority_district
    primary_contact_email { Faker::Internet.email(domain: domains[0]) }
  end
end
