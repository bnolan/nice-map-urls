class CreatePlaces < ActiveRecord::Migration
  def change
    create_table :places do |t|
      t.float :latitude, :longitude
      t.string :path
      t.text :geocode
      
      t.timestamps
    end
  end
end
