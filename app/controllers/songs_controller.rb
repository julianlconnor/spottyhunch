require 'open-uri'
require 'cgi'

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
  
  def similar
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
