class MainAccountExpense < ApplicationRecord
  self.inheritance_column = :_type_disabled

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :description, presence: true
end
