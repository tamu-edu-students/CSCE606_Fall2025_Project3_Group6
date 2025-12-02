class ListItem < ApplicationRecord
  belongs_to :list
  belongs_to :movie

  validates :movie_id, uniqueness: { scope: :list_id }
end
