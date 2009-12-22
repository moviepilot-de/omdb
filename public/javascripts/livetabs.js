var LiveTabs = Class.create();
LiveTabs.prototype = {
  initialize: function( active_tab ) {
    this.current_tab = active_tab;
  },
  click: function( name ) {
    this.deactivate_tab( this.current_tab );
    this.activate_tab( name );
  },
  activate_tab: function( name ) {
    this.current_tab = name;
    $('tab_link_' + name).addClassName('active');
    Element.show( 'tab_' + name);
  },
  deactivate_tab: function( name ) {
    $('tab_link_' + name).removeClassName('active');
    Element.hide('tab_' + name);
  }
}