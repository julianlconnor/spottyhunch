

//jQuery when DOM loads run this
$(function(){

	//Backbone Model

	window.Song = Backbone.Model.extend({
	  
		url: function() {
			return this.id ? '/songs/' + this.id : '/songs'; //Ternary, look it up if you aren't sure
		},

		initialize: function(){
		//Can be used to initialize Model attributes
		},
		
		clear: function() {
      this.destroy();
      this.view.remove();
    }
    
	});
	
	window.Error = Backbone.Model.extend({

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
		
		className: "track",
    
		events: { 
			"click span.expand"           : "expand",
			"click span.expand.active"	  : "collapse",
			"click span.delete"           : "clear",
		},

		initialize: function(){
		  this.model.bind('change', this.render);
      this.model.view = this;
		},

    clear: function() {
      this.model.clear();
    },

		expand: function(){
		  var expand = $(this.el).find(".expand");
		  if (expand.hasClass("active")){
		    expand.html("<img src='images/expand.png'/>");
		  }
		  else {
		    expand.html("<img src='images/contract.png'/>");
		  }
		  expand.toggleClass("active");
			var id = this.model.id;
			if ($("ol."+id).children().length > 0) {
				$("ol."+id).slideToggle();		
			}
			else {
			  expand.html("<img class='loading' src='images/24.gif'/>");
				$.getJSON('/similar/'+this.model.id, function(data) {
            if(data && data.length > 0) {
              var songs = _(data).map(
                function(i) {
                //alert(JSON.stringify(i));
                return jQuery.parseJSON('{"track":"'+i.track+'","artist":"'+i.artist+'","image":"'+i.image+'","artistUrl":"'+i.artistUrl+'","trackUrl":"'+i.trackUrl+'","album":"'+i.album+'","albumUrl":"'+i.albumUrl+'","released":"'+i.year+'"}');
              });
              $.each(songs,function(){
                //alert(JSON.stringify(this));
                $("ol."+id).append(ich.similar_song_item(this));
              });
              expand.html("<img src='images/contract.png'/>");
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
		
		remove: function() {
      $(this.el).remove();
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
	
	window.ErrorView = Backbone.View.extend({
	  tagName: "span",
	  
	  initialize: function(){
	    
	  },
	
	  
	  render: function(){
	    var error = this.model.toJSON();
	    $(this.el).html(ich.error_item(error));
	    return this
	  }
	})

	//Application View
	window.AppView = Backbone.View.extend({

	  el: $("#songs_app"),

	  events: {
	    "submit form#new_song": "createSong",
	    "keypress input#song_artist": "createOnEnter"
	  },

	  initialize: function(){
	    _.bindAll(this, 'addOne', 'addAll');
      Songs.bind('change', this.render);
	    Songs.bind('add', this.addOne);
	    Songs.bind('reset', this.addAll);
	    Songs.bind('all', this.render);
    
	    Songs.fetch(); //This Gets the Model from the Server
	  },
  
	  addOne: function(song) {
	    if (!song.get("error"))
	    {
	      var view = new SongView({model: song});
  	    this.$("#song_list").append(view.render().el);
	    }
  	  else {
  	    console.log("Error");
  	    var error = new ErrorView({model:song});
  	    this.$("#flash_space").html(error.render().el);
  	  }
	  },
  
	  addAll: function(){
	    Songs.each(this.addOne);
	  },
  
	  newAttributes: function(event) {
	    var new_song_form = $(event.currentTarget).serializeObject();
	    //alert (JSON.stringify(new_dog_form));
	    return { song: {
	        track: new_song_form["song[track]"],
	        artist: new_song_form["song[artist]"]
	      }}
	    console.log('Clearing form data.');
      $("input#song_track").text = "";
      $("input#song_artist").text = "";
	  },
	
    createOnEnter: function(e) {
      //console.log("CreateOnEnter:" + e.keyCode);
      if(e.keyCode != 13) return;
      var params = this.newAttributes(e);
      Songs.create(params);
      // this.$("#song_list").append(song.render().el);
      //console.log("lolcats" + song);
    },
  
	  createSong: function(e) {
      e.preventDefault(); //This prevents the form from submitting normally

      var params = this.newAttributes(e);

      Songs.create(params);

      //TODO - Clear the form fields after submitting
	  }

	});

	//START THE BACKBONE APP
	window.App = new AppView;

});
