require 'rails_helper'

RSpec.describe "Users", type: :request do
  include Warden::Test::Helpers

  before do
    Warden.test_mode!
  end

  after do
    Warden.test_reset!
  end

  describe "GET #show (profile)" do
    it "requires authentication" do
      get profile_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows current user's profile when signed in" do
      user = create(:user, username: "u#{SecureRandom.hex(6)}")
      login_as(user, scope: :user)

      get profile_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(user.username)
    end
  end

  describe "GET /users/:username (public_profile)" do
    it "renders public profile when profile_public is true (requires auth)" do
      viewer = create(:user, username: "v#{SecureRandom.hex(4)}")
      login_as(viewer, scope: :user)
      user = create(:user, username: "u#{SecureRandom.hex(6)}", profile_public: true)
      get public_profile_path(username: user.username)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(user.username)
    end

    it "redirects when profile_public is false (requires auth)" do
      viewer = create(:user, username: "v#{SecureRandom.hex(4)}")
      login_as(viewer, scope: :user)
      user = create(:user, username: "u#{SecureRandom.hex(6)}", profile_public: false)
      get public_profile_path(username: user.username)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET #edit and PATCH #update" do
    it "allows signed-in user to edit and update profile" do
      user = create(:user, username: "u#{SecureRandom.hex(6)}")
      login_as(user, scope: :user)

      get "/settings/profile"
      expect(response).to have_http_status(:success)
      patch "/settings/profile", params: { user: { username: "newname_#{SecureRandom.hex(3)}" } }
      expect(response).to redirect_to(profile_path)
      expect(user.reload.username).to start_with('newname_')
    end

    it "renders edit on invalid update" do
      user = create(:user, username: "u#{SecureRandom.hex(6)}")
      login_as(user, scope: :user)

      patch "/settings/profile", params: { user: { username: 'x' } }
      expect(response).to have_http_status(:success).or have_http_status(:unprocessable_entity)
    end
  end
end
require 'rails_helper'

RSpec.describe "Users", type: :request do
  include Warden::Test::Helpers

  before do
    Warden.test_mode!
  end

  after do
    Warden.test_reset!
  end

  describe "GET /profile (show)" do
    it "shows the signed-in user's profile" do
      user = create(:user)
      login_as(user, scope: :user)

      get profile_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(user.username)
    end

    it "redirects anonymous users to sign in" do
      get profile_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "GET /settings/profile and PATCH update" do
    it "renders edit and updates successfully" do
      user = create(:user)
      login_as(user, scope: :user)

      get "/settings/profile"
      expect(response).to have_http_status(:success)

      patch "/settings/profile", params: { user: { username: "newname", profile_public: false } }
      expect(response).to redirect_to(profile_path)
      expect(user.reload.username).to eq("newname")
      expect(user.reload.profile_public).to be false
    end

    it "renders edit when update invalid" do
      user = create(:user)
      login_as(user, scope: :user)

      patch "/settings/profile", params: { user: { username: "" } }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /u/:username (public_profile)" do
    it "shows public profile when profile_public is true (requires auth in current app)" do
      viewer = create(:user)
      login_as(viewer, scope: :user)
      user = create(:user, profile_public: true)
      get public_profile_path(username: user.username)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(user.username)
    end

    it "redirects to root when profile is private (authenticated viewer)" do
      viewer = create(:user)
      login_as(viewer, scope: :user)
      user = create(:user, profile_public: false)
      get public_profile_path(username: user.username)
      expect(response).to redirect_to(root_path)
    end
  end
end
