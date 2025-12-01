class ListsController < ApplicationController
  before_action :authenticate_user!, except: [ :show ]
  before_action :set_list, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_user!, only: [ :edit, :update, :destroy ]

  def index
    @lists = current_user.lists
  end

  def show
    unless @list.public || @list.user == current_user
      redirect_to root_path, alert: "This list is private."
    end
  end

  def new
    @list = List.new
  end

  def create
    @list = current_user.lists.build(list_params)
    if @list.save
      redirect_to @list, notice: "List created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @list.update(list_params)
      redirect_to @list, notice: "List updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @list.destroy
    redirect_to profile_path, notice: "List deleted successfully."
  end

  private

  def set_list
    @list = List.find(params[:id])
  end

  def authorize_user!
    unless @list.user == current_user
      redirect_to root_path, alert: "Not authorized."
    end
  end

  def list_params
    params.require(:list).permit(:name, :description, :public)
  end
end
