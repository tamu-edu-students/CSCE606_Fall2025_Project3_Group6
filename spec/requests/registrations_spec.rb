require 'rails_helper'

RSpec.describe "Registrations", type: :request do
  include Warden::Test::Helpers

  before do
    Warden.test_mode!
  end

  after do
    Warden.test_reset!
  end

  describe "POST /users (sign up)" do
    it "creates a user with username permitted" do
      expect {
        post user_registration_path, params: { user: { email: "test+#{SecureRandom.hex(4)}@example.com", username: "u#{SecureRandom.hex(4)}", password: "Password1!", password_confirmation: "Password1!" } }
      }.to change(User, :count).by(1)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PUT /users (account update)" do
    it "updates profile_public when current password provided" do
      user = create(:user, password: "Password1!", password_confirmation: "Password1!", username: "u#{SecureRandom.hex(6)}")
      login_as(user, scope: :user)

      put user_registration_path, params: { user: { profile_public: false, current_password: "Password1!" } }
      expect(response).to redirect_to(root_path).or have_http_status(:redirect)
      expect(user.reload.profile_public).to eq(false)
    end
  end
end
require 'rails_helper'

RSpec.describe "Registrations", type: :request do
  include Warden::Test::Helpers

  before do
    Warden.test_mode!
  end

  after do
    Warden.test_reset!
  end

  describe "POST /users (sign up)" do
    it "creates a new user with valid params" do
      expect {
        post user_registration_path, params: { user: { email: "spec+#{SecureRandom.hex(4)}@example.com", username: "user#{SecureRandom.hex(3)}", password: "Password123", password_confirmation: "Password123" } }
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:redirect)
    end

    it "renders errors with invalid params" do
      post user_registration_path, params: { user: { email: "bad", password: "x", password_confirmation: "y" } }
      expect(response).to have_http_status(:unprocessable_entity).or have_http_status(:success)
    end
  end

  describe "PATCH /users (account update)" do
    it "updates account when current_password is provided" do
      user = create(:user, password: "Password123", password_confirmation: "Password123")
      login_as(user, scope: :user)

      patch user_registration_path, params: { user: { username: "newname", current_password: "Password123" } }
      expect(response).to have_http_status(:redirect)
      expect(user.reload.username).to eq("newname")
    end

    it "does not update with incorrect current_password" do
      user = create(:user, password: "Password123", password_confirmation: "Password123")
      login_as(user, scope: :user)

      patch user_registration_path, params: { user: { username: "newname", current_password: "wrong" } }
      expect(response).to have_http_status(:unprocessable_entity).or have_http_status(:success)
      expect(user.reload.username).not_to eq("newname")
    end
  end
end
