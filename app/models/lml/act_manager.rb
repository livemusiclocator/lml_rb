# frozen_string_literal: true

module Lml
  class ActManager < ApplicationRecord
    belongs_to :user, class_name: "Lml::User"
    belongs_to :act, class_name: "Lml::Act"
  end
end
