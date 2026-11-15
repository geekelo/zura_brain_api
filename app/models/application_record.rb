class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def as_json(options = nil)
    super(options).except("id")
  end
end
