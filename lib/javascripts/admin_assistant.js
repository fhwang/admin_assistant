/******************************************************************************
Don't edit this file: It gets re-copied every time the server starts.
******************************************************************************/

var AdminAssistant = {};
AdminAssistant.show_search_form = function() {
  $('search_form').show();
};

AdminAssistant.PolymorphicFieldSearch = Class.create();
AdminAssistant.PolymorphicFieldSearch.prototype = {
  initialize: function(name, types) {
    this.name = name;
    this.hiddenFieldId = 'search_' + name + '_id';
    this.hiddenTypeFieldId = 'search_' + name + '_type';
    this.autocompleteTypes = types.autocompleteTypes;
    this.autocompleters = {};
    this.autocompleteTypes.each(function(autocompleteType) {
      options = {
        clearLink: autocompleteType.clearLink,
        includeBlank: true,
        modelName: autocompleteType.name,
        palette: autocompleteType.palette,
        paletteClonesInputWidth: false,
        parameters: autocompleteType.parameters,
        paramName: autocompleteType.name + '_autocomplete_input',
        textField: autocompleteType.textField
      };
      options.afterAutocomplete = function(value) {
        this.hiddenTypeField().value = autocompleteType.type;
        this.clearInputsExceptFor(autocompleteType.name);
      }.bind(this);
      options.afterClearSelected = function(value) {
        this.hiddenTypeField().value = '';
      }.bind(this);
      autocompleter = new AdminAssistant.RestrictedAutocompleter(
        autocompleteType.name, this.hiddenFieldId, autocompleteType.url,
        options
      );
      this.autocompleters[autocompleteType.name] = autocompleter;
    }, this);
    this.idTypes = types.idTypes;
    this.idTypes.each(function(idType) {
      Event.observe(
        this.name + '_' + idType.name + "_id", 'keyup', 
        this.setHiddenFieldsFromIdField.bind(this)
      );
    }, this);
    this.selectTypes = types.selectTypes;
    this.selectTypes.each(function(selectType) {
      Event.observe(
        this.name + '_' + selectType.name + "_id", 'change', 
        this.setHiddenFieldsFromSelectField.bind(this)
      );
    }, this);
  },
  
  clearHiddenFields: function() {
    this.hiddenField().value = '';
    this.hiddenTypeField().value = '';
  },
  
  clearInputsExceptFor: function(name_to_not_clear) {
    this.autocompleteTypes.each(function(autocompleteType) {
      if (autocompleteType.name != name_to_not_clear) {
        var autocompleter = this.autocompleters[autocompleteType.name]
        autocompleter.clearTextField();
        autocompleter.setClearLinkVisibility();
      }
    }, this);
    this.idTypes.each(function(idType) {
      if (idType.name != name_to_not_clear) {
        $(this.name + '_' + idType.name + '_id').value = '';
      }
    }, this);
    this.selectTypes.each(function(selectType) {
      if (selectType.name != name_to_not_clear) {
        $(this.name + '_' + selectType.name + '_id').value = '';
      }
    }, this);
  },
  
  hiddenField: function() {
    return $(this.hiddenFieldId);
  },
  
  hiddenTypeField: function() {
    return $(this.hiddenTypeFieldId);
  },
  
  setHiddenFieldsFromIdField: function(event) {
    input = event.findElement();
    idType = this.idTypes.detect(function(idt) {
      return (this.name + '_' + idt.name + '_id' == input.id);
    }, this);
    if (input.value == '') {
      if (this.hiddenTypeField().value == idType.type) {
        this.clearHiddenFields();
      }
    } else {
      this.hiddenField().value = input.value;
      this.hiddenTypeField().value = idType.type;
      this.clearInputsExceptFor(idType.name);
    }
  },
  
  setHiddenFieldsFromSelectField: function(event) {
    select = event.findElement();
    selectType = this.selectTypes.detect(function(st) {
      return (this.name + '_' + st.name + '_id' == select.id);
    }, this);
    if (select.value == '') {
      if (this.hiddenTypeField().value == selectType.type) {
        this.clearHiddenFields();
      }
    } else {
      this.hiddenField().value = select.value;
      this.hiddenTypeField().value = selectType.type;
      this.clearInputsExceptFor(selectType.name);
    }
  }
}

/*
This autocompleter restricts based on a list of names and matching IDs; the IDs
are set in a hidden field. Arguments 
*/
AdminAssistant.RestrictedAutocompleter = Class.create();
AdminAssistant.RestrictedAutocompleter.prototype = {
  initialize: function(name, hiddenField, url, options) {
    this.name = name;
    this.textField = options.textField || (this.name + '_autocomplete_input');
    this.palette = options.palette || (this.name + '_autocomplete_palette');
    this.selectedTextFieldValue = $(this.textField).value;
    this.hiddenField = hiddenField;
    this.includeBlank = options.includeBlank;
    this.modelName = options.modelName || this.name;
    this.clearLink = options.clearLink || ('clear_' + this.name + '_link');
    ajaxAutocompleterOptions = {
      afterUpdateElement: this.autocompleteAfterUpdateElement.bind(this),
      fullSearch: true,
      onHide: this.autocompleteOnHide,
      parameters: options.parameters,
      paramName: options.paramName,
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
    this.afterAutocomplete = options.afterAutocomplete;
    this.afterClearSelected = options.afterClearSelected;
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
    if (this.afterAutocomplete) { this.afterAutocomplete(selected_value); }
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
    this.clearTextField();
    this.setClearLinkVisibility();
    if (this.afterClearSelected) { this.afterClearSelected(); }
  },
  
  clearTextField: function() {
    $(this.textField).value = '';
  },
  
  setClearLinkVisibility: function() {
    if ($(this.textField).value == '') {
      $(this.clearLink).hide();
    } else {
      if (this.includeBlank) { $(this.clearLink).show(); }
    }
  }
}

