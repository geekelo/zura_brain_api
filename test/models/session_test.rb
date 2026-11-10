require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "assigns a uuid session code on create" do
    client = Client.create!(name: "Ada", phone: "0800")
    session = Session.create!(client: client)

    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/, session.session_code)
  end
end
