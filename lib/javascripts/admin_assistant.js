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
  initialize: function(name, hiddenField, url, options) {
    this.name = name;
    this.textField = this.name + '_autocomplete_input';
    this.palette = this.name + '_autocomplete_palette';
    this.selectedTextFieldValue = $(this.textField).value;
    this.hiddenField = hiddenField;
    this.includeBlank = options.includeBlank;
    this.modelName = options.modelName || this.name;
    this.clearLink = 'clear_' + this.name + '_link';
    ajaxAutocompleterOptions = {
      afterUpdateElement: this.autocompleteAfterUpdateElement.bind(this),
      fullSearch: true,
      onHide: this.autocompleteOnHide,
      parameters: options.parameters,
      partialChars: 1,
    };
    if (!options.paletteClonesInputWidth) {
      ajaxAutocompleterOptions.onShow = function(element, update){
        if(!update.style.position || update.style.position=='absolute') {
          update.style.position = 'absolute';
          Position.clone(element, update, {
            setHeight: false,
            setWidth: false,
            offsetTop: element.offsetHeight
          });
        }
        Effect.Appear(update,{duration:0.15});
      };
    }
    var ac = new Ajax.Autocompleter(
      this.textField, this.palette, url, ajaxAutocompleterOptions
    );
    this.changeArrowBehavior(ac);
    this.setClearLinkVisibility();
    Event.observe(this.clearLink, 'click', function(event) {
      this.clearSelected();
    }.bind(this));
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
    var selected_value = selectedElement.id.substr(this.modelName.length)
    
    // If they have more complex markup inside the selection, get the "title" element
    var title_element = selectedElement.down(".title")
    if (title_element) selectedElement = title_element
    
    $(this.hiddenField).value = selected_value
    this.selectedTextFieldValue =
        selectedElement.innerHTML.unescapeHTML().strip();
    this.setClearLinkVisibility();
  },
  
	/*
	Refresh the text fill-in field to the value reflected in the underlying
	hidden input fields
	*/
	autocompleteOnHide: function( element, update ) {
    if (this.selectedTextFieldValue) {
      element.value = this.selectedTextFieldValue;
    }
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
    $(this.hiddenField).value = '';
    $(this.textField).value = '';
    this.setClearLinkVisibility();
  },
  
  setClearLinkVisibility: function() {
    if ($(this.hiddenField).value != '') {
      if (this.includeBlank) { $(this.clearLink).show(); }
    } else {
      $(this.clearLink).hide();
    }
  }
}

