

//jQuery when DOM loads run this
$(function(){

	//Backbone Model

	window.Song = Backbone.Model.extend({
	  
		url: function() {
			return this.id ? '/songs/' + this.id : '/songs'; //Ternary, look it up if you aren't sure
		},

		initialize: function(){
		//Can be used to initialize Model attributes
		}
	});
	

	//Collection
	window.SongCollection = Backbone.Collection.extend({
		model: Song,
		url: '/'
	});

	window.Songs = new SongCollection();
	
	// Similar Track
	
	//Song View
	window.SongView = Backbone.View.extend({
		tagName: "li",

		events: { 
			"dblclick div.listTrackContent" : "expand",
			"dblclick li.active"		   	: "collapse",
			//"dblclick p.viewTrackContent"  : "render"
		},

		initialize: function(){

		},

		expand: function(){
			$(this.el).addClass("active");
			var id = this.model.id;
			if ($("ol."+id).children().length > 0) {
				$("ol."+id).slideToggle();		
			}
			else {
				$.getJSON('/similar/'+this.model.id, function(data) {
		            if(data && data.length > 0) {
		                var songs = _(data).map(
							function(i) {
								//alert(JSON.stringify(i));
								return jQuery.parseJSON('{"title":"'+i.title+'","artist":"'+i.artist+'","image":"'+i.image+'","artistUrl":"'+i.artistUrl+'","trackUrl":"'+i.trackUrl+'"}');
						});
		                $.each(songs,function(){
							//alert(JSON.stringify(this));
							$("ol."+id).append(ich.similar_song_item(this));
						});
		            }
					else {
		                new Error({ message: "Last.fm sucks." });
					}
		        });
			}
			//Template stuff goes here
			// $("#songs_app").html(ich.song_template(song));
			// 			return this
		},
		
		collapse: function(){
			$(this.el).removeClass("active");
		},
		
		render: function(){
			var song = this.model.toJSON();
			//Template stuff goes here
			$(this.el).html(ich.song_item(song));
			return this
		},
		
		setContent: function() {
			// var title = this.model.get('title');
			// 			var artist = this.model.get('artist');
			// 			this.$('.todo-content').text(content);
			// 			this.input = this.$('.todo-input');
			// 			this.input.bind('blur', this.close);
			// 			this.input.val(content);
	    },
	});

	//Application View
	window.AppView = Backbone.View.extend({

	  el: $("#songs_app"),

	  events: {
	    "submit form#new_song": "createSong"
	  },

	  initialize: function(){
	    _.bindAll(this, 'addOne', 'addAll');
	
      console.log('initialize');

      this.song_title = this.$("#song_title")[0];
      this.song_artist = this.$("#song_artist")[0];
    
	    Songs.bind('add', this.addOne);
	    Songs.bind('reset', this.addAll);
	    Songs.bind('all', this.render);
    
	    Songs.fetch(); //This Gets the Model from the Server
	  },
  
	  addOne: function(song) {
	    var view = new SongView({model: song});
	    this.$("#song_list").append(view.render().el);
	  },
  
	  addAll: function(){
	    Songs.each(this.addOne);
	  },
  
	  newAttributes: function(event) {
	    var new_song_form = $(event.currentTarget).serializeObject();
	    //alert (JSON.stringify(new_dog_form));
	    return { song: {
	        title: new_song_form["song[title]"],
	        artist: new_song_form["song[artist]"]
	      }}
	  },
	
    createOnEnter: function(e) {
      if(e != 13) return;
      var params = this.newAttributes(e);
      var song = Songs.create(params);
      this.$("#song_list").append(song.render().el);
      //console.log("lolcats" + song);
    },
  
	  createSong: function(e) {
	    e.preventDefault(); //This prevents the form from submitting normally
    
	    var params = this.newAttributes(e);
    
	    Songs.create(params);
    
	    //TODO - Clear the form fields after submitting
		this.song_title.value = '';
		this.song_artist.value = '';
	  }

	});

	//START THE BACKBONE APP
	window.App = new AppView;

});
