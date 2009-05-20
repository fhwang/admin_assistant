/******************************************************************************
Don't edit this file: It gets re-copied every time the server starts.
******************************************************************************/

var AdminAssistant = {};
AdminAssistant.show_search_form = function() {
  $('search_form').show();
};

/*
This autocompleter restricts based on a list of names and matching IDs; the IDs
are set in a hidden field.
*/
AdminAssistant.RestrictedAutocompleter = Class.create();
AdminAssistant.RestrictedAutocompleter.prototype = {
  initialize: function(name, hidden_field, url, exclude_blank, options) {
    this.name = name;
    this.text_field = name + "_autocomplete_input";
    this.div_to_populate = name + "_autocomplete_palette";
    this.selected_name = $(this.text_field).value;
    this.hidden_field = hidden_field;
    this.exclude_blank = exclude_blank;
    options.fullSearch = true;
    options.partialChars = 1;
    options.afterUpdateElement = this.autocompleteAfterUpdateElement.bind(this);
    options.onHide = this.autocompleteOnHide;
    var ac = new Ajax.Autocompleter(
      this.text_field, this.div_to_populate, url, options
    );
    this.changeArrowBehavior(ac);
    this.setClearLinkVisibility();
  },
  
  /*
  This is the callback that fires after a selection is made from the 
  autocompleter results.
  
  In addition to setting hidden id fields, it will place the text label of the 
  selected item in the search field. It assumes that your selectedElement is
  one with simple text contents or some markup structure with an element of 
  class "title". In the latter case, it will use the text of the "title"
  element.
  */
  autocompleteAfterUpdateElement: function(element, selectedElement) {
    var id_name = element.id;
    var input_id       = id_name.substr(id_name.length - 1)
    var selected_value = selectedElement.id.substr(this.name.length)
    
    // If they have more complex markup inside the selection, get the "title" element
    var title_element = selectedElement.down(".title")
    if (title_element) selectedElement = title_element
    
    $(this.hidden_field).value = selected_value
    this.selected_name = selectedElement.innerHTML.unescapeHTML().strip();
    this.setClearLinkVisibility();
  },
  
	/*
	Refresh the text fill-in field to the value reflected in the underlying
	hidden input fields
	*/
	autocompleteOnHide: function( element, update ) {
    if (this.selected_name) { element.value = this.selected_name; }
		new Effect.Fade(update,{duration:0.15});
	},
  
  /*
  Overriding totally wierd arrow-up and arrow-down scrolling behavior built
  into the autocompleter in scriptaculous 1.7.0
  */
  changeArrowBehavior: function(ac) {
    ac.markPrevious = function() {
      if(this.index > 0) this.index--
        else this.index = this.entryCount-1;
    };
    ac.markNext = function() {
      if(this.index < this.entryCount-1) this.index++
        else this.index = 0;
    };
  },
  
  clearSelected: function() {
    $(this.hidden_field).value = '';
    $(this.text_field).value = '';
    this.setClearLinkVisibility();
  },
  
  setClearLinkVisibility: function() {
    if ($(this.hidden_field).value != '') {
      if (!this.exclude_blank) {
        $('clear_' + this.name + '_link').show();
      }
    } else {
      $('clear_' + this.name + '_link').hide();
    }
  }
}

