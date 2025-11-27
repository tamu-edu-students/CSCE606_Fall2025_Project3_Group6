require 'rails_helper'

RSpec.describe 'Log as Watched', type: :feature do
  include Warden::Test::Helpers

  before do
    Warden.test_mode!
  end

  after do
    Warden.test_reset!
  end

  it 'allows a signed-in user to log a movie as watched from the movie page' do
    user = create(:user)
    login_as(user, scope: :user)
    movie = create(:movie, cached_at: Time.current)
    # Stub TMDB calls to avoid external HTTP requests during feature tests
    allow_any_instance_of(TmdbService).to receive(:similar_movies).and_return({ "results" => [] })

    # Use the movie's TMDB id in the path so the controller finds the cached movie
    visit movie_path(movie.tmdb_id)
    expect(page).to have_button('Log as Watched')

    click_button 'Log as Watched'

    expect(WatchLog.where(user_id: user.id, movie_id: movie.id).count).to eq(1)
    expect(page).to have_text('Watch count:')
    expect(page).to have_selector('strong', text: '1')
  end
end
