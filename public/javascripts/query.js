// Thanks to Trac for some inspiration

var QueryFilters = Class.create();

QueryFilters.prototype = {
  initialize: function( label, type, value, id ) {
    this.counter = 0;
    this.base_element = $('query_filter_table_body');
    filter = this.createFilter( type, label, value, id );
    filter.removable = false;
    this.renderFilter( filter );
    this.counter = this.counter + 1;
  },

  addFilter: function( label, type, value, id ) {
    filter = this.createFilter( type, label, value, id );
    this.renderFilter( filter );
    this.counter = this.counter + 1;
  },

  renderFilter: function( filter ) {
    this.createTableRow( filter.label );
    this.createInputElement( filter );
    if (filter.removable)
      this.createRemoveButton();
    this.base_element.appendChild( this.tr );
  },

  createTableRow: function( label ) {
    this.tr = document.createElement('tr');
    this.tr.id = 'row_' + this.counter;
    this.tr.appendChild( this.createTableHeader( label ) );
  },

  createTableHeader: function( text ) {
    th = document.createElement('th');
    th.appendChild( this.createLabel( text ) );
    return th;
  },

  createLabel: function( text ) {
    label = document.createElement('label');
    labelText = document.createTextNode( text );
    label.appendChild( labelText );
    return label;
  },

  createRemoveButton: function() {
    td = document.createElement('td');
    button = document.createElement('input');
    button.type = 'submit';
    button.value = '-';
    button.onclick = function(){ Element.remove(this.parentNode.parentNode); return false; };
    td.appendChild(button);
    this.tr.appendChild( td );
  },

  createInputElement: function( filter ) {
    td     = document.createElement('td');
    elements = filter.createInputElements();
    for (i=0; i < elements.length; i++) {
      td.appendChild( elements[i] );
    }
    this.tr.appendChild( td );
  },

  createFilter: function( type, label, value, id ) {
    return new Filter( label, type, type, value, id, this.counter );
  }
};

var Filter = Class.create();

Filter.prototype = {
  initialize: function( label, type, name, value, id, counter ) {
    this.label   = label;
    this.type    = type;
    this.name    = name;
    this.value   = value;
    this.id      = id;
    this.counter = counter;
    this.inputElements = new Array();
    this.removable = true;
  },

  autocomplete_url: function() {
    return "/search/" + this.type + "_autocomplete"
  },

  autocomplete_name: function() {
    return this.name + "_ac";
  },

  createInputElements: function() {
    switch(this.type) {
      case '':
        break;
      default:
	this.createAutocompleteField();
	this.createHiddenField();
        new Ajax.Autocompleter( this.inputElements[0], this.inputElements[1], 
	        this.autocomplete_url(), { afterUpdateElement: setHiddenValue, minChars: 2 } )
        break;
    }
    return this.inputElements;
  },

  createInputField: function() {
    input = document.createElement('input');
    input.name  = this.name;
    input.id    = this.name + "_" + this.counter;
    input.value = this.value;
    input.type  = 'text';
    this.inputElements.push( input );
  },

  createAutocompleteField: function() {
    this.createInputField();
    div = document.createElement('div');
    div.name = this.name;
    div.style.display = 'none';
    div.className = 'auto-complete';
    this.inputElements.push( div );
  },

  createHiddenField: function() {
    hidden = document.createElement('input');
    hidden.type  = 'hidden';
    hidden.name  = this.name + '_ar[]';
    hidden.value = this.id;
    hidden.id    = this.name + "_" + this.counter + "_hidden";
    this.inputElements.push( hidden );
  }
};

var MovieFilter = Class.create();

MovieFilter.prototype = {
  initialize: function( domId ) {
    this.domId  = domId;
    this.extractMovieIds(); 
    this.offset = 0;
  },

  showMovies: function( ids, offset, rest ) {
    Element.scrollTo('content');
    Element.hide('more-movies');
    this.removeMovies( ids );
    this.offset = offset;
    for (i = 0; i < ids.length; i++) {
      this.showMovie( ids[i] );
    }
    this.extractMovieIds(); 
    Effect.Fade('ajax-activity-indicator', {queue: 'end', duration: 0.3});
    if (rest > 0) {
      $('more-movies').onclick = function(){new Ajax.Request('/movie_filter/update_filter?offset=' + (offset + 18), {asynchronous:true, evalScripts:true, onLoading:function(request){Element.show('ajax-activity-indicator')}, parameters:Form.serialize('movie-filter-form')}); return false;}
      Effect.Appear('more-movies', {queue: 'end'});
    }
  },

  showMovie: function( id ) {
    if (this.movieBoxPresent( id )) {
      if (! this.getDomIdForMovie( id ).visible ) {
        Effect.Appear( this.getDomIdForMovie( id ), {queue: 'end', duration: 0.4} );
      }
    } else {
      new Ajax.Request('/movie/' + id + '/search_box', { onSuccess: insertMovie });
    }
  },

  removeMovies: function( ids ) {
    for (i = 0; i < this.movies.length; i++) {
      if (this.movieBoxPresent( this.movies[i] ) && 
          this.movieBoxVisible( this.movies[i] )) {
        if (ids.indexOf( this.movies[i] ) == -1) {
          this.removeMovie( this.movies[i] );
	}
      }
    }
  },

  removeMovie: function( id ) {
    Effect.DropOut(this.getDomIdForMovie( id ), {queue: 'end', duration: 0.4});
  },

  movieBoxPresent: function( id ) {
    if ($(this.getDomIdForMovie(id)) == undefined) {
      return false;
    } else {
      return true;
    }
  },

  movieBoxVisible: function( id ) {
    return Element.visible(this.getDomIdForMovie(id));
  },

  getDomIdForMovie: function( id ) {
    return "movie_search_result_" + id;
  },

  extractMovieIds: function() {
    this.movies = new Array();
    elements = document.getElementsByClassName('result-box', this.domId);
    for (var i = 0; i < elements.length; i++) {
      this.movies.push( elements[i].id.split("_").pop() );
    }
  }
}

setHiddenValue = function( input, div ) {
  id = input.id;
  element = id + "_hidden";
  $(element).value = div.id.split("_").pop();
}

insertMovie = function( t ) {
  html = t.responseText;
  new Insertion.Bottom('movies', html);

}
