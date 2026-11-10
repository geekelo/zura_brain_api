require "test_helper"

class Pos::TherapistTest < ActiveSupport::TestCase
  test "returns the work name for a matching code" do
    Therapist.create!(work_name: "Ada", code: "ADA1")

    assert_equal "Ada", Pos::Therapist.name_for_code("ADA1")
  end

  test "returns nil when no therapist has the code" do
    assert_nil Pos::Therapist.name_for_code("MISSING")
  end
end
