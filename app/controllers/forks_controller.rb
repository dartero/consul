class ForksController < ApplicationController
  skip_authorization_check

  def index
    @forks = Fork.all.order(:name)
  end

  def show
    @fork = Fork.find(params[:id])
  end

end