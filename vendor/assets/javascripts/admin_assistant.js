var AdminAssistant = {};

$(document).ready(function() {
    $('.clear_datetime_select').click(function(event) {
        name = $(event.target).attr('data-prefix');
        $.each([1,2,3,4,5], function(i, val) {
            $('#' + name + '_' + val + 'i').attr('value', '');
        });
        return false;
    });
    
    $('.index #show_search_form').click(function() {
        $('#search_form').show();
        return false;
    });
    
    $('.index a.destroy').click(function(event) {
        jqElt = $(event.target);
        if (confirm(jqElt.attr('data-confirm'))) {
          url = jqElt.attr('href');
          jqTr = jqElt.closest('tr')
          $.post(
            url,
            {"_method": jqElt.attr('data-method')},
            function() {
              jqTr.fadeOut();
            }
          );
        }
        return false;
    });
    
    $('.index a.toggle').on('click', function(event) {
        url = $(event.target).attr('href');
        container = '#' + $(event.target).parent().attr('id');
        $.post(
          url,
          {_method: 'PUT'},
          function(data) {
            $(container).fadeOut(50, function() {
              $(container).html(data);
              $(container).fadeIn()
            });
          }
        );
        return false;
    });
});

AdminAssistant.PolymorphicFieldSearch = function(name) {
  this.name = name;
  this.initialize();
};

AdminAssistant.PolymorphicFieldSearch.prototype = {
  initialize: function() {
    this.initAutocompleters();
    this.initSelectors();
    this.initTextFields();
  },
  
  initAutocompleters: function() {
    var fieldSearch = this;
    $.each(this.autocompleterElts(), function(i, elt) {
        var valueType = $(elt).attr('data-value-type')
        var opts = {
          'crossDomain': false, 'tokenLimit': 1,
          'onAdd': function(item) {
            fieldSearch.tokenInputOnAdd(item, valueType, elt);
          },
          'onDelete': function(item) {
            fieldSearch.tokenInputOnDelete(item, valueType);
          }
        };
        var initialId = $(elt).attr('data-initial-id');
        var initialName = $(elt).attr('data-initial-name');
        if (initialId && initialName) {
          opts['prePopulate'] = [{'id': initialId, 'name': initialName}];
        }
        $(elt).tokenInput($(elt).attr('data-autocomplete-url'), opts)
    });
  },
  
  initSelectors: function() {
    var fieldSearch = this;
    $.each(this.selectorElts(), function(i, elt) {
        $(elt).bind('change', function(evt) {
            fieldSearch.update(
              $(this).val(), $(this).attr('data-value-type'), this
            );
        });
    });
  },
  
  initTextFields: function() {
    var fieldSearch = this;
    $.each(this.textFieldElts(), function(i, elt) {
        $(elt).bind('keyup', function(evt) {
            fieldSearch.update(
              $(this).val(), $(this).attr('data-value-type'), this
            );
        });
    });
  },
  
  autocompleterElts: function() {
    var acElts = [];
    $("#" + this.rootId() + " input").each(function(i, elt) {
        if ($(elt).attr('data-behavior') == 'autocomplete') {
          acElts.push(elt);
        }
    });
    return acElts;
  },
  
  clearAutocompleterView: function(elt) {
    containerDiv =
      "#polymorphic_search_" + $(elt).attr('id').replace(/_id/, '');
    // 1. remove the div containing the selected token
    $(containerDiv + " .token-input-token").remove();
    // 2. show the autocompleter input with a blank value
    $(containerDiv + " input[autocomplete=off]").show().val("");
  },
  
  rootId: function() {
    return "polymorphic_search_" + this.name;
  },
  
  selectorElts: function() {
    sElts = [];
    $("#" + this.rootId() + " select").each(function(i, elt) {
        if ($(elt).attr('data-behavior') == 'select') {
          sElts.push(elt);
        }
    });
    return sElts;
  },
  
  textFieldElts: function() {
    var tfElts = []
    $("#" + this.rootId() + " input[type!=hidden]").each(function(i, elt) {
        if ($(elt).attr('data-behavior') == 'id') {
          tfElts.push(elt);
        }
    });
    return tfElts;
  },
  
  tokenInputOnAdd: function(item, valueType, updatedElt) {
    this.update(item.id, valueType, updatedElt);
  },
  
  tokenInputOnDelete: function(item, valueType) {
    this.update(null, null, null);
  },
  
  update: function(id, type, updatedElt) {
    $('#search_' + this.name + "_id").val(id);
    $('#search_' + this.name + "_type").val(type);
    var fieldSearch = this;
    $.each(this.autocompleterElts(), function(i, elt) {
        idFromUpdatedElt = $(updatedElt).attr('id');
        idFromThisAutocompleter = $(elt).attr('id');
        if (idFromUpdatedElt != idFromThisAutocompleter) {
          fieldSearch.clearAutocompleterView(elt);
        }
    });
    $.each(this.selectorElts(), function(i, elt) {
        if (elt != updatedElt) { $(elt).val(''); }
    });
    $.each(this.textFieldElts(), function(i, elt) {
        if (elt != updatedElt) { $(elt).val(''); }
    });
  }
};


