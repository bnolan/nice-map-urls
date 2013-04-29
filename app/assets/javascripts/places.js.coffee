# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

class GeocodeResult extends Backbone.Model
  isEstablishment: ->
    _(@get('types')).detect( (i) -> i == "establishment" )    
    
  getPathComponents: ->
    pathComponents = for c in @get('address_components') when c.types[0] != 'postal_code'
      c.long_name
    
    if @isEstablishment()
      pathComponents.unshift(@get('name'))

    pathComponents = for c in pathComponents
      c.toLowerCase().replace(/[-\s]+/g,'-')
    
    pathComponents = _.uniq(pathComponents)
    
    pathComponents.reverse()
  
  getAddress: ->
    @get 'formatted_address'
    
  getPath: ->
    @getPathComponents().join("/")
  
  getLatitude: ->
    @get('geometry').location.lat()

  getLongitude: ->
    @get('geometry').location.lng()
    
  # The results for establishments dont include the full path, so we gotta regeocode
  reGeocode: (callback) ->
    geocoder = new google.maps.Geocoder()
    
    geocoder.geocode { 'address': @getAddress() }, (results, status) =>
      @set { address_components : results[0].address_components }
      @save()
    
  save: ->
    # no op!
    console.log "GeocodeResult#save is a no-op, should be redefined"
    console.log @
    
class SearchView
  constructor: (place) ->
    @place = place
    
    $('#map').css {
      height : $(window).height() - $('form').height() - $('.footer').height() - 40
    }

    $('form').submit @onSubmit
    
    @createMap()
    @addAutocomplete()
  
  onSubmit: (e) =>
    e.preventDefault()
    
  createMap: ->
    mapType = google.maps.MapTypeId.ROADMAP

    options = {
      zoom: 3
      center: new google.maps.LatLng(45, 0)
      mapTypeId: mapType
      mapTypeControl : true
      panControl : false
      zoomControl : true
      streetViewControl : true
      scrollwheel : true
    }

    if @place
      options.zoom = Math.min(18, @place.path.split('/').length * 3)
      options.center = new google.maps.LatLng(@place.latitude, @place.longitude)

    @map = new google.maps.Map($('#map')[0], options)
    
    if @place
      @addInfowindow()
      
  addInfowindow: ->
    @marker = new google.maps.Marker {
      position : new google.maps.LatLng(@place.latitude, @place.longitude)
      map : @map
      title: @place.geocode.name
    }
    
    @infowindow = new google.maps.InfoWindow
    @infowindow.open @map, @marker
    @infowindow.setContent(@template()({ place : @place.geocode }))
  
  template: ->
    _.template('''
    
      <h3><%= place.name %></h3>
      
      <address>
        <%= place.formatted_address.split(',').join(",<br />") %>
      </address>
    
    ''')
    
  
  addAutocomplete: ->
    input = document.getElementById('searchTextField');
    options = {
      # types: ['establishment'] # 'geocode']
    }

    @autocomplete = new google.maps.places.Autocomplete($('form>input')[0], options)

    google.maps.event.addListener @autocomplete, 'place_changed', @onAutocomplete
    
  onAutocomplete: =>
    @savePlace(new GeocodeResult(@autocomplete.getPlace()))
    
  resolveAndGoto: (path) ->
    geocoder = new google.maps.Geocoder()
    
    address = path.split('/').reverse().join(", ")
    
    geocoder.geocode { 'address': address }, (results, status) =>
      place = new GeocodeResult(results[0])
      
      place.getPath = ->
        path
        
      @savePlace(place)
    
  savePlace: (place) ->
    place.save = ->
      params = {
        path : place.getPath()
        latitude : place.getLatitude()
        longitude : place.getLongitude()
        geocode : JSON.stringify(place.attributes)
      }
    
      for k,v of params
        $("#place_#{k}").val(v)

      $('form').unbind().submit()
      
    
    if place.isEstablishment()
      place.reGeocode()
    else
      place.save()
    

      # if (!place.geometry) {
      #   // Inform the user that a place was not found and return.
      #   return;
      # }
      # 
      # // If the place has a geometry, then present it on a map.
      # if (place.geometry.viewport) {
      #   // Use the viewport if it is provided.
      #   map.fitBounds(place.geometry.viewport);
      # } else {
      #   // Otherwise use the location and set a chosen zoom level.
      #   map.setCenter(place.geometry.location);
      #   map.setZoom(17);
      # }
      # var image = {
      #   url: place.icon,
      #   size: new google.maps.Size(71, 71),
      #   origin: new google.maps.Point(0, 0),
      #   anchor: new google.maps.Point(17, 34),
      #   scaledSize: new google.maps.Size(25, 25)
      # };
      # marker.setIcon(image);
      # marker.setPosition(place.geometry.location);
      # 
      # infowindow.setContent(place.name);
      # infowindow.open(map, marker);
    
    
@SearchView = SearchView