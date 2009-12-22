var reference_movie_selected;
var object_select_state;
var check_method;
var info_cache = new Array();

function object_selected() {
  object_select_state = true;
}

function object_unselected() {
  object_select_state = false;
}

function is_object_selected() {
  return object_select_state;
}

function movie_selected() {
  reference_movie_selected = true;
}

function movie_unselected() {
  reference_movie_selected = false;
}

function displaySortIcons(htmlId, text) {
  link_id = 'link-sort-' + htmlId;
  list = document.getElementById(htmlId);
  handles = document.getElementsByClassName("handle", list);
  for (var i = 0; i < handles.length ; i++) {
    window.setTimeout("displayItem(handles[" + i + "])", 15 * i);
  }
  $(link_id).old_onclick = $(link_id).onclick;
  $(link_id).old_text = $(link_id).firstChild.nodeValue;
  $(link_id).onclick = function(){ removeSortIcons(htmlId, $(link_id).old_text); return false };
  Element.update(link_id, text);
}

function removeSortIcons(htmlId, text) {
  link_id = 'link-sort-' + htmlId;
  list = document.getElementById(htmlId);
  handles = document.getElementsByClassName("handle", list);
  for (var i = 0; i < handles.length ; i++) {
    handles[i].style.display = "none";
  }
  $(link_id).onclick = $(link_id).old_onclick;
  Element.update(link_id, text);
}

function local_alias_check_method( htmlId ) {
  if (htmlId.value == "new") {
    htmlId.parentNode.blur();
    Effect.BlindDown('new_alias_input', {duration:0.2, afterFinish: focusElement});
  } else {
    Effect.BlindUp('new_alias_input', {duration:0.2});
  }
}

function focusElement( obj ) {
  obj.element.focus();
}


function displayVoteIcons(htmlId, text) {
	link_id = 'category-voting';
	vote_buttons = document.getElementsByClassName("actions", htmlId);
	for (var i = 0; i < vote_buttons.length ; i++) {
		window.setTimeout("displayItem(vote_buttons[" + i + "])", 15 * i);
	}
	$(link_id).old_onclick = $(link_id).onclick;
  $(link_id).old_text = $(link_id).firstChild.nodeValue;
  $(link_id).onclick = function(){ removeVoteIcons(htmlId, $(link_id).old_text); return false };
	Element.update('category-voting', text);
}

function removeVoteIcons(htmlId, text) {
  link_id = 'category-voting';
	vote_buttons = document.getElementsByClassName("actions", htmlId);
	for (var i = 0; i < vote_buttons.length ; i++) {
    vote_buttons[i].style.display = "none";
	}
	$(link_id).onclick = $(link_id).old_onclick;
  Element.update(link_id, text);
}

function displayItem(element) {
  element.style.display = "inline";
}

function checkEnter(e){
  var character
	// check for ie vs. moz
	if ( e && (e.keyCode || e.which) ) {
	  if (e.keyCode) {
	    character = e.keyCode
	  } else {
	    character = e.which
	  }
	}	else {
	  // supposedly its an ie needs to use event.keyCode instead
  	character = event.keyCode
  }
  // char 27 is ESC
  if (character == 27) {
    box.deactivate();
  }
	// char 13 is the return/enter key
  if(character == 13) { 
  	// return false on return/enter
	  return false 
	} else { 
	  return true
  }
}


create_li = function( id ) {
  li    = document.createElement('li');
  li.id = id;
  return li;
}

create_hidden_field = function( name, value ) {
  hidden = document.createElement('input');
  hidden.type = 'hidden';
  hidden.name = name;
  hidden.value = value;
  return hidden;
}

create_a = function( text ) {
  a = document.createElement('a');
  a.href = "#";
  a.appendChild(text);

  return a;
}

removeEmptyListItem = function( parentNode ) {
  var elements = document.getElementsByClassName('empty', parentNode);
  for (i=0; i < elements.length; i++) {
    Element.remove( elements[i] );
  }
}

displayCategoryInformation = function( id ) {
  displayAdditionalInformation( 'category', id );
}

displayPersonInformation = function( id ) {
  displayAdditionalInformation( 'person', id );
}

displayMovieInformation = function( id ) {
  displayAdditionalInformation( 'movie', id );
}

displayJobInformation = function( id ) {
  displayAdditionalInformation( 'job', id );
}

displayCompanyInformation = function( id ) {
  displayAdditionalInformation( 'company', id );
}

displayAdditionalInformation = function( type, id ) {
  if (!Element.visible('more-information')) {
    return;
  }
  if (info_cache[type + id] == undefined) {
    Element.update('more-information', '<div class="help-text loading">&nbsp;</div>');
    var request = new Ajax.Request( '/' + type + '/' + id + '/info?size=2', {asynchronous:false,method:'get'});
    info_cache[type + id] = request.transport.responseText; 
  }
  Element.update('more-information', info_cache[type + id]);
}

setCategoryParent = function( id ) {
  displayCategoryInformation(id);
  $('category_parent').value = id;
}

setJobParent = function( id ) {
  displayJobInformation(id);
  $('job_parent').value = id;
}

setCompanyParent = function( id ) {
  displayCompanyInformation(id);
  $('company_parent').value = id;
}

toggleDetails = function() {
  visible = Element.visible('more-information') ? true : false;
  if (visible) {
    Element.hide('more-information')
    $('more-information-headline').className = 'closed';
    details_shown = false;
  } else {
    Element.show('more-information')
    $('more-information-headline').className = 'open';
    details_shown = true;
  }
}


// New Cast/Crew Functions

setJob = function( txt, selectedListItem ) {
  var id = selectedListItem.id.split("_").pop();
  if (id == '0') { return }
  $('crew_job').value = id;
  $('selected_job').firstChild.nodeValue = txt.value;
  checkCrewForm();
}

setCrewPerson = function( txt, selectedListItem ) {
  var id = selectedListItem.id.split("_").pop();
  if (id == '0') { 
    return
  } else if (id == 'new') {
    $('new_crew_person').value = txt.value;
  } else {
    $('crew_person').value = id;
    $('new_crew_person').value = '';
  }
  $('crew_selected_person').firstChild.nodeValue = txt.value;
  checkCrewForm();
}

setCastPerson = function( txt, selectedListItem ) {
  var id = selectedListItem.id.split("_").pop();
  if (id == '0') {
    return
  } else if (id == 'new') { 
    $('new_cast_person').value = txt.value;
  } else {
    $('cast_person').value = id;
    $('new_cast_person').value = '';
  }
  $('cast_selected_person').firstChild.nodeValue = txt.value;
  checkCastForm();
}

startSearching = function( element ) {
  $(element).blur();
}

clearCrewForm = function() {
  $('crew_person').value = '';
  $('crew_person_autocomplete').value = '';
  $('crew_selected_person').firstChild.nodeValue = "-";
  $('new_crew_person').value = '';
  $('job_autocomplete').value = '';
  $('crew_job').value = '';
  $('selected_job').firstChild.nodeValue = "-";
  $('crew_person_autocomplete').focus();
}

clearCastForm = function() {
  $('cast_person').value = '';
  $('cast_person_autocomplete').value = '';
  $('cast_selected_person').firstChild.nodeValue = "-";
  $('new_cast_person').value = '';
  $('cast_comment').value = '';
  $('cast_person_autocomplete').focus();
}

checkCrewForm = function () {
  if (($('crew_person').value != "" || $('new_crew_person').value != "") && 
      ($('crew_job').value != "") || $('new_crew_job').value != "") {
    $('add_crew_button').disabled = false;
  } else {
    $('add_crew_button').disabled = true;
  }
}

checkCastForm = function () {
  if (($('cast_person').value != "" || $('new_cast_person').value != "") && 
      ($('cast_comment').value != "")) {
    $('add_cast_button').disabled = false;
  } else {
    $('add_cast_button').disabled = true;
  }
}

limitTextSize = function(textarea, counter, max) {
	if ($(textarea).value.length > max) {
		$(textarea).value = $(textarea).value.substring(0, max);
	} else {
		$(counter).value = max - $(textarea).value.length;
	}
}

updateStub = function(url) {
  if ($('stub') != undefined) {
    new Ajax.Updater('stub', url);
  }
}

closeTrailer = function() {
  box.deactivate();
  $('overlay').style.opacity = 0.8;
  $('overlay').style.background = '#DCDCDC';
}