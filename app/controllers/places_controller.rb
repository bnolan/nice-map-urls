class PlacesController < ApplicationController
  
  def create
    path = Iconv.iconv('ascii//ignore//translit', 'utf-8', params[:place][:path]).to_s.downcase.gsub(/[^0-9a-z\-\/]/,'')

    place = Place.find_or_create_by_path(path)
    
    place.latitude = params[:place][:latitude].to_f
    place.longitude = params[:place][:longitude].to_f
    
    place.geocode = JSON.parse(params[:place][:geocode])
    
    place.save!
    
    redirect_to '/' + place.path
  end

  def show
    @path = params[:path]
    
    @place = Place.find_by_path(@path)
    
    render :action => :index
  end
  
end
