// adds the dropped item to the textarea in the omdb link style
function surround(areaName, prefix, suffix) {
   // preliminary implementation only works on selected text for now
   var textarea = document.getElementById(areaName)
   var text, curPos, start, end
   if (document.selection) {
      // internet explorer can use the shorter version
      curPos = textarea.caretPos
      text = document.selection.createRange().text;
      document.selection.createRange().text = prefix + text + suffix
      textarea.caretPos = curPos + 1
   } else if (textarea.setSelectionRange) {
      // longer one for mozilla/safari
      scrollPos = textarea.scrollTop
      start = textarea.selectionStart
      end = textarea.selectionEnd
      selection = textarea.value.substring(start, end)
      selection = prefix + selection + suffix
      textarea.value =
         textarea.value.substring(0, start)
         + selection + textarea.value.substring(end)
      textarea.setSelectionRange(start + prefix.length, start + suffix.length)
      textarea.scrollTop = scrollPos
   }
   textarea.focus()
   return false
}

function surround_extlink(areaName) {
  return surround( areaName, '"', '":http://' );
}



// add an element (usually a dragged and dropped item) as omdb link
// to the textarea
// the link will be created from the element's id, i.e. movie_1234
// will result in [[m:1234]]
function addItem(element) {
  var textarea, item, prefix, link
  textarea = $('wiki_text')
  if (!element.match(/[a-z]+_[0-9]+/)) {
    return
  }
  item = element.split("_")
  prefix = item[0]
  link = '[[' + prefix + ':' + item[1] + ']]'
  // insert at current selection
  if (document.selection) {
    // internet explorer
    sel = document.selection.createRange().text
    document.selection.createRange().text = sel + link
  } else if (textarea.setSelectionRange) {
    // the others
    scrollPos = textarea.scrollTop
    start = textarea.selectionStart
    end = textarea.selectionEnd
    selection = textarea.value.substring(start, end)
    selection = selection + link
    textarea.value =
       textarea.value.substring(0, start)
       + selection + textarea.value.substring(end)
    textarea.scrollTop = scrollPos
  } else {
    // the rest
    textarea.value = textarea.value + link
  }
  textarea.focus()
}

function preview(url) {
  data = document.forms[1].elements["content[data]"].value
  new Ajax.Request(url, {postBody:data})
  Element.show('wiki-preview')
}

function checkImageSource() {
  if ($('picture').value != null && $('picture').value.length > 0 && $('source').value.strip().length == 0) {
    alert($('picture').value);
    $('wiki-preview').update('Image source required');
    $('wiki-preview').show();
    return false;
  } 

  if ($('picture').value != null && $('source').value.strip().length > 0) {
    $('upload-indicator').show();
  }
  $('form-upload').disabled = true;
  $('form-submit').disabled = true;
  $('form-submit').form.submit();
}