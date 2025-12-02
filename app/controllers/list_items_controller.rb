class ListItemsController < ApplicationController
  before_action :authenticate_user!

  def create
    @list = current_user.lists.find(params[:list_id])
    @movie = Movie.find(params[:movie_id])

    @list_item = @list.list_items.build(movie: @movie)

    if @list_item.save
      redirect_back(fallback_location: movie_path(@movie), notice: "Added to list.")
    else
      redirect_back(fallback_location: movie_path(@movie), alert: "Could not add to list.")
    end
  end

  def destroy
    @list_item = ListItem.find(params[:id])
    if @list_item.list.user == current_user
      @list_item.destroy
      redirect_back(fallback_location: root_path, notice: "Removed from list.")
    else
      redirect_back(fallback_location: root_path, alert: "Not authorized.")
    end
  end
end
