class TechPayinPayout < ApplicationRecord
  self.table_name = "tech_payins_payouts"
  self.inheritance_column = :_type_disabled

  belongs_to :extra_account, class_name: "ExtraAccountPayinPayout", optional: true
end
