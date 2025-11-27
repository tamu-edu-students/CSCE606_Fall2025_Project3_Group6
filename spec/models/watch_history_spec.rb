require 'rails_helper'

RSpec.describe WatchHistory, type: :model do
  it 'has a valid factory' do
    expect(create(:watch_history)).to be_valid
  end

  it 'belongs to a user' do
    hist = create(:watch_history)
    expect(hist.user).to be_present
  end

  it 'has many watch_logs' do
    hist = create(:watch_history)
    log = create(:watch_log, watch_history: hist)
    expect(hist.watch_logs).to include(log)
  end

  it 'validates uniqueness of user_id' do
    user = create(:user)
    create(:watch_history, user: user)
    second = build(:watch_history, user: user)
    expect(second).not_to be_valid
    expect(second.errors[:user_id]).to include("has already been taken")
  end
end
