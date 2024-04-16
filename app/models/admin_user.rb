class AdminUser < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise(:database_authenticatable, :recoverable, :rememberable, :validatable)

  def self.ransackable_attributes(auth_object = nil)
    [
      "created_at",
      "email",
      "id",
      "time_zone",
      "id_value",
      "updated_at",
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  validates(
    :time_zone,
    inclusion: {
      in: Lml::Timezone::CANONICAL_TIMEZONES,
      message: "invalid time zone",
    },
  )
end
