require 'open-uri'
require 'cgi'
require 'em-http-request'

class SongsController < ApplicationController
  # GET /songs
  # GET /songs.json
  def index
    @songs = Song.all
    @song = Song.new
    respond_to do |format|
      format.html # index.html.erb
      format.json  { render :json => @songs }
    end
  end

  # GET /songs/1
  # GET /songs/1.json
  def show
    @song = Song.find(params[:id])
  
    respond_to do |format|
      format.html # show.html.erb
      format.json  { render :json => @song }
    end
  end
  
  def similar_no_parallel
    #Event Machine ~ HTTP Client
    @s = Song.find(params[:id])
    @tracks = []
    @out = []
    # Query for 10 similar artists to the artist of the song with params[:id]
    similar_artists = "http://ws.audioscrobbler.com/2.0/?method=artist.getsimilar&artist=" + URI.encode(@s.artist) + "&limit=8&api_key=46717f37e986f321258ffb9d1191b489"
    begin
      @artists = []
      # artistUrls holds the last.fm url of each artist
      artistUrls = Hash.new
      # Fetch xml of similar artists
      @doc = Nokogiri::XML(open(similar_artists))
      # Loop through each artist and grab their name and url
      @doc.xpath("//artist").each do |node|
        @artists << node.xpath("./name").text
        artistUrls[@artists.last] = node.xpath("./url").text
      end
      # Loop through each similar artist and fetch their top tracks, then find the spotify url of each track
      for artist in @artists
        top_tracks = "http://ws.audioscrobbler.com/2.0/?method=artist.gettoptracks&artist=" + URI.encode(artist) + "&limit=2&api_key=46717f37e986f321258ffb9d1191b489"
        @doc = Nokogiri::XML(open(top_tracks))
        @doc.xpath("//track").each do |node|
          
          # Fetch info from spotify to grab its uri, sanitize inputs
          t = CGI.escape(node.xpath("./name").text)
          a = CGI.escape(artist)
          puts "http://ws.spotify.com/search/1/track?q=#{a}+#{t}"
          @sp = Nokogiri::XML(open("http://ws.spotify.com/search/1/track?q=#{a}+#{t}"))
          # if @sp.nil?
          #debugger
          # if the first entry that spotify returns is equivalent
          #Need to make this conditional "smarter"
          if @sp.xpath("//xmlns:track").length > 0 #&& @sp.xpath("//xmlns:track").first.xpath("./xmlns:name").text == node.xpath("./name").text #&& @sp.xpath("//xmlns:track").first.xpath(".//xmlns:artist/xmlns:name").text == artist    
            @out << {
              "track"     =>  node.xpath("./name").text,
              "artist"    =>  artist,
              "trackUrl"  =>  node.xpath("./url").text,
              "artistUrl" =>  artistUrls[artist],
              "spotifyUrl"=>  @sp.xpath("//xmlns:track").first['href']
            }
          end
        end
      end
      #@out.shuffle!
      # debugger
    rescue Exception => e
      puts e.message + ("\n")
      puts e.backtrace.join("\n")
    end
    render :json => @out
  end
    
  # Asynchronously handle HTTP Requests
  def similar
    @s = Song.find(params[:id])
    @out = []
    @artists = []
    @spotify_urls = []
  
    puts "Query for 10 similar artists to the artist of the song with params[:id]"
    similar_artists = "http://ws.audioscrobbler.com/2.0/?method=artist.getsimilar&artist=" + URI.encode(@s.artist) + "&limit=15&api_key=46717f37e986f321258ffb9d1191b489"
  
    puts "artistUrls holds the last.fm url of each artist"
    artistUrls = Hash.new
  
    puts "Fetch xml of similar artists."
    @doc = Nokogiri::XML(open(similar_artists))
  
    puts "Loop through each artist and grab their name and url."
    @doc.xpath("//artist").each do |node|
      @artists << node.xpath("./name").text
      artistUrls[@artists.last] = node.xpath("./url").text
    end

    EventMachine.run do
      
      
      puts "Instantiate multi request."
      multi_lastfm = EventMachine::MultiRequest.new
      
      puts "Build new MultiRequest for Last.fm."
      url = "http://ws.audioscrobbler.com/2.0/?method=artist.gettoptracks&limit=2&api_key=46717f37e986f321258ffb9d1191b489&artist="
      @artists.each {|artist| multi_lastfm.add(EventMachine::HttpRequest.new(url+"#{URI.encode(artist)}").get)}

      multi_lastfm.callback {
        puts "Handle successfull top track fetches by iterating through and fetching spotify url."
        multi_lastfm.responses[:succeeded].each do |resp|

          @doc = Nokogiri::XML(resp.response)
          
          puts "Solely fetch artist and track names for spotify lookup."
          @doc.xpath("//track").each do |node|
            t = CGI.escape(node.xpath("./name").text)
            a = CGI.escape(node.xpath(".//artist/name").text)
            @spotify_urls << "http://ws.spotify.com/search/1/track?q=#{t}+#{a}"
          end
          
        end
        
        puts "Build new MultiRequest for Spotify."
        multi_spotify = EventMachine::MultiRequest.new
        @spotify_urls.each {|url| multi_spotify.add(EventMachine::HttpRequest.new(url).get)}
        
        multi_spotify.callback {
          
          puts "Handle successfull fetches from spotify and build @out object."
          multi_spotify.responses[:succeeded].each do |resp|
            @doc = Nokogiri::XML(resp.response)
            @node = @doc.xpath("//xmlns:track").first
            begin
              @out << {
                "track"       =>  @node.xpath(".//xmlns:name").first.text,
                "trackUrl"    =>  @node.first[1],
                "artist"      =>  @node.xpath(".//xmlns:artist/xmlns:name").text,
                "artistUrl"   =>  @node.xpath("./xmlns:artist").first['href'],
                "album"       =>  @node.xpath(".//xmlns:album/xmlns:name").first.text,
                "albumUrl"    =>  @node.xpath("./xmlns:album").first['href'],
                "year"        =>  @node.xpath(".//xmlns:album/xmlns:released").first.text
              }
            rescue

            end
          end
          puts "Stop Event Machine."
          EventMachine.stop
        }
      }
    end
    render :json => @out
  end
  
  def similar_tracks
    @s = Song.find(params[:id])
    @tracks = []
    @out = []
    #similar_artists = "http://ws.audioscrobbler.com/2.0/?method=artist.getsimilar&artist=" + URI.encode(@s.artist) + "&limit=5&api_key=46717f37e986f321258ffb9d1191b489"
    link = "http://ws.audioscrobbler.com/2.0/?method=track.getsimilar&artist=" + URI.encode(@s.artist) + "&track=" + URI.encode(@s.track) + "&limit=15&api_key=46717f37e986f321258ffb9d1191b489"
    begin
      @doc = Nokogiri::XML(open(link))
      @doc.xpath("//track").each do |node|
        
        @out <<  {
                      "track"     => node.xpath("./name").text,
                      "artist"    => node.xpath(".//artist/name").text,
                      "trackUrl"  => node.xpath("./url").text,
                      "artistUrl" => node.xpath(".//artist/url").text,
                      "duration"  => node.xpath("./duration").text,
                      "image"     => node.xpath("./image[@size='medium']").text
                    }
      end
    rescue
      @out = "Bad Request"
    end
    render :json => @out
  end

  # GET /songs/new
  # GET /songs/new.json
  def new
    @song = Song.new

    respond_to do |format|
      format.html # new.html.erb
      format.json  { render :json => @song }
    end
  end

  # GET /songs/1/edit
  def edit
    @song = Song.find(params[:id])
  end

  # POST /songs
  # POST /songs.json
  def create
    link = "http://ws.audioscrobbler.com/2.0/?method=track.getinfo&artist=#{URI.encode(params[:song][:artist])}&track=#{URI.encode(params[:song][:track])}&api_key=46717f37e986f321258ffb9d1191b489"
    begin
      @doc = Nokogiri::XML(open(link))
      @out =  {
        "track"         =>  @doc.xpath("//track/name").text,
        "trackUrl"      =>  @doc.xpath("//track/url").text,
        "artistUrl"     =>  @doc.xpath("//track//artist/url").text,
        "artist"        =>  @doc.xpath("//track//artist/name").text
      } 
      #debugger
      @song = Song.new(@out)
      respond_to do |format|
        if @song.save
          format.html { redirect_to(@song, :notice => 'Song was successfully created.') }
          format.json  { render :json => @song, :status => :created, :location => @song }
        else
          format.html { render :action => "new" }
          format.json  { render :json => @song.errors, :status => :unprocessable_entity }
        end
      end
    rescue
      @song = {:error=>"#{params[:song][:track]} by #{params[:song][:artist]} was not recognized by Last.fm"}
      render :json => @song
    end
  end

  # PUT /songs/1
  # PUT /songs/1.json
  def update
    @song = Song.find(params[:id])

    respond_to do |format|
      if @song.update_attributes(params[:song])
        format.html { redirect_to(@song, :notice => 'Song was successfully updated.') }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.json  { render :json => @song.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /songs/1
  # DELETE /songs/1.json
  def destroy
    @song = Song.find(params[:id])
    @song.destroy

    respond_to do |format|
      format.html { redirect_to(songs_url) }
      format.json  { head :ok }
    end
  end
end
