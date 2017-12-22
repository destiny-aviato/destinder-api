# frozen_string_literal: true

class Character < ApplicationRecord
  belongs_to :user, optional: true
  has_many :character_details
  has_many :item_sets
end