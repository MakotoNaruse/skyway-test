class RoomsController < ApplicationController

  def join

  end

  def show
    @roomId = params[:id]
  end
end
