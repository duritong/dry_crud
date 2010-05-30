# A view helper to standartize often used functions like formatting, 
# tables, forms or action links. This helper is ideally defined in the 
# ApplicationController.
module StandardHelper
  
  NO_LIST_ENTRIES_MESSAGE = "No entries available"
  CONFIRM_DELETE_MESSAGE  = 'Do you really want to delete this entry?'
  
  ################  FORMATTING HELPERS  ##################################

  # Define an array of associations symbols in your helper that should not get automatically linked.
  #def no_assoc_links = [:city]
  
  # Formats a single value
  def f(value)
    case value
      when Fixnum then value.to_s
      when Float  then "%.2f" % value
			when Date	  then value.to_s
      when Time   then value.strftime("%H:%M")   
      when true   then 'yes'
      when false  then 'no'
    else 
      value.respond_to?(:label) ? h(value.label) : h(value.to_s)
    end
  end
  
  # Formats an arbitrary attribute of the given ActiveRecord object.
  # If no specific format_{attr} method is found, formats the value as follows:
  # If the value is an associated model, renders the label of this object.
  # Otherwise, calls format_type.
  def format_attr(obj, attr)
    format_attr_method = :"format_#{attr.to_s}"
    if respond_to?(format_attr_method)
      send(format_attr_method, obj)
    elsif assoc = belongs_to_association(obj, attr)
      format_assoc(obj, assoc)
    else
      format_type(obj, attr)
    end
  end
  
  # Formats an active record association
  def format_assoc(obj, assoc)
    if assoc_val = obj.send(assoc.name)
      link_to_unless(no_assoc_link?(assoc), h(assoc_val.label), assoc_val)
    else
			'(none)'
    end
  end
  
  # Returns true if no link should be created when formatting the given association.
  def no_assoc_link?(assoc)
    (respond_to?(:no_assoc_links) &&
     no_assoc_links.to_a.include?(assoc.name.to_sym)) || 
    !respond_to?("#{assoc.klass.name.underscore}_path".to_sym)
  end
  
  # Formats an arbitrary attribute of the given object depending on its data type.
  # For ActiveRecords, take the defined data type into account for special types
  # that have no own object class.
  def format_type(obj, attr)
    val = obj.send(attr)
    return "" if val.nil?
    case column_type(obj.class, attr)
      when :time then val.strftime("%H:%M")
      when :date then val.to_date.to_s
      when :text then simple_format(h(val))
    else f(val)
    end
  end
  
  # Returns the ActiveRecord column type or nil.
  def column_type(clazz, attr)
    column_property(clazz, attr, :type)
  end
  
  # Returns an ActiveRecord column property for the passed attr or nil
  def column_property(clazz, attr, property)
    if clazz.respond_to?(:columns_hash)
      column = clazz.columns_hash[attr.to_s]
      column.try(property)
    end  
  end
  
  # Returns the :belongs_to association for the given attribute or nil if there is none.
  def belongs_to_association(obj, attr)
    if attr.to_s =~ /_id$/ && obj.class.respond_to?(:reflect_on_all_associations)
      obj.class.reflect_on_all_associations(:belongs_to).find do |a| 
        a.primary_key_name == attr.to_s && !a.options[:polymorphic]
      end
    end
  end
  
  
  ##############  STANDARD HTML SECTIONS  ############################
  
  
  # Renders an arbitrary content with the given label. Used for uniform presentation.
  # Without block, this may be used in the form <%= labeled(...) %>, with like <% labeled(..) do %>
  def labeled(label, content = nil, &block)
    content = capture(&block) if block_given?
    html = render(:partial => 'shared/labeled', :locals => { :label => label, :content => content})
    block_given? ? concat(html) : html  
  end
  
  # Transform the given text into a form as used by labels or table headers.
  def captionize(text, clazz = nil)
    if clazz.respond_to?(:human_attribute_name)
      clazz.human_attribute_name text
    else
      text.to_s.humanize.titleize      
    end
  end
  
  # Renders a list of attributes with label and value for a given object. 
  # Optionally surrounded with a div.
  def render_attrs(obj, attrs, div = true)
    html = attrs.collect do |a| 
      labeled(captionize(a, obj.class), format_attr(obj, a))
    end.join
    
    if div
      content_tag(:div, html, :class => 'attributes')
    else
      html
    end
  end
  
  # Renders a table for the given entries as defined by the following block.
  # If entries are empty, an appropriate message is rendered.
  def table(entries, &block)
    if entries.present?
      StandardTableBuilder.table(entries, self, &block)
    else
      content_tag(:div, NO_LIST_ENTRIES_MESSAGE, :class => 'list')
    end
  end
  
  # Renders a generic form for all given attributes using StandardFormBuilder.
  # If a block is given, a custom form may be rendered and attrs is ignored.
  # The form is always directly printed into the erb, so the call must
  # go within a normal <% form(...) %> section, not in a <%= output section
  def form(object, attrs = [], options = {})
    form_for(object, {:builder => StandardFormBuilder}.merge(options)) do |form|
      concat form.error_messages
      
      if block_given? 
        yield(form)
      else
        concat form.labeled_input_fields(*attrs)
      end
      
      concat labeled("&nbsp;", form.submit("Save"))
    end
  end
  
  # Alternate table row
  def tr_alt(&block)
    content_tag(:tr, :class => cycle("even", "odd", :name => "row_class"), &block)
  end
  
  # Intermediate method to use the RenderInheritable module. 
  # Because ActionView has a different :render method than ActionController, 
  # this method provides an entry point to use render_inheritable from views.
  # Strictly, this method would belong into a render_inheritable helper.
  def render_inheritable(options)                
    inheritable_partial_options(options) if options[:partial]  
    render options
  end   
 
  
  ######## ACTION LINKS ###################################################### :nodoc:
  
  # Standard link action to the show page of a given record.
  def link_action_show(record)
    link_action 'Show', record
  end
  
  # Standard link action to the edit page of a given record.
  def link_action_edit(record)
    link_action 'Edit', edit_polymorphic_path(record)
  end
  
  # Standard link action to the destroy action of a given record.
  def link_action_destroy(record)
    link_action 'Delete', record, :confirm => CONFIRM_DELETE_MESSAGE, :method => :delete
  end
  
  # Standard link action to the list page.
  def link_action_index(url_options = {:action => 'index'})
    link_action 'List', url_options
  end
  
  # Standard link action to the new page.
  def link_action_add(url_options = {:action => 'new'})
    link_action 'Add', url_options
  end
  
  # A generic helper method to create action links.
  # These link may be styled to look like buttons, for example.
  def link_action(label, options = {}, html_options = {})
    link_to("[#{label}]", options, {:class => 'action'}.merge(html_options))
  end
  
end