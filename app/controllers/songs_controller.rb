require 'open-uri'

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
    @s = Song.find(params[:id])
    @tracks = []
    @out = []
    link = "http://ws.audioscrobbler.com/2.0/?method=track.getsimilar&artist=" + URI.encode(@s.artist) + "&track=" + URI.encode(@s.title) + "&limit=15&api_key=46717f37e986f321258ffb9d1191b489"
    begin
      @doc = Nokogiri::XML(open(link))
      @doc.xpath("//track").each do |node|
        @out <<  {
                      "title"     => node.xpath("./name").text,
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
    link = "http://ws.audioscrobbler.com/2.0/?method=track.getinfo&artist=#{URI.encode(params[:song][:artist])}&track=#{URI.encode(params[:song][:title])}&api_key=46717f37e986f321258ffb9d1191b489"
    begin
      @doc = Nokogiri::XML(open(link))
      @doc.xpath("//track").each do |node|
        @out <<  {
                      "track"         =>  node.xpath("./name").text,
                      "trackUrl"      =>  node.xpath("./url").text,
                      "artistUrl"     =>  node.xpath(".//artist/url").text,
                      "artist"        =>  node.xpath(".//artist/name").text,
                      "image"         =>  node.xpath(".//album/image[@size='large']").text
                    }
      end
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
