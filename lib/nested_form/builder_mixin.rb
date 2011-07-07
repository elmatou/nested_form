module NestedForm
  module BuilderMixin
    # Adds a link to insert a new associated records. The first argument is the name of the link, the second is the name of the association.
    #
    #   f.link_to_add("Add Task", :tasks)
    #
    # You can pass HTML options in a hash at the end and a block for the content.
    #
    #   <%= f.link_to_add(:tasks, :class => "add_task", :href => new_task_path) do %>
    #     Add Task
    #   <% end %>
    #
    # See the README for more details on where to call this method.
    def link_to_add(*args, &block)
      options = args.extract_options!.symbolize_keys
      association = args.pop
      @nested_wrapper_tag = options.delete(:wrapper_tag) || @nested_wrapper_tag
      @nested_builder = options.delete(:builder) || @nested_builder
      options[:class] = [options[:class], "add_nested_fields"].compact.join(" ")
      options["data-association"] = association

      options["data-insert-node"] = options.delete(:node)
      options["data-insert-position"] = options.delete(:position)

      args << (options.delete(:href) || "javascript:void(0)")
      args << options
      @fields ||= {}
      @template.after_nested_form(association) do
        model_object = object.class.reflect_on_association(association).klass.new
        output = %Q[<textarea id="#{association}_fields_blueprint" style="display: none">].html_safe
        output << fields_for(association, model_object, :child_index => "new_#{association}", :builder => @nested_builder, &@fields[association])
        output.safe_concat('</textarea>')
        output
      end
      @template.link_to(*args, &block)
    end

    # Adds a link to remove the associated record. The first argument is the name of the link.
    #
    #   f.link_to_remove("Remove Task")
    #
    # You can pass HTML options in a hash at the end and a block for the content.
    #
    #   <%= f.link_to_remove(:class => "remove_task", :href => "#") do %>
    #     Remove Task
    #   <% end %>
    #
    # See the README for more details on where to call this method.
    def link_to_remove(*args, &block)
      options = args.extract_options!.symbolize_keys
      options[:class] = [options[:class], "remove_nested_fields"].compact.join(" ")
      args << (options.delete(:href) || "javascript:void(0)")
      args << options
      hidden_field(:_destroy) + @template.link_to(*args, &block)
    end

    def fields_for_with_nested_attributes(association_name, *args)
      # TODO Test this better
      block = args.pop || Proc.new { |fields| @template.render(:partial => "#{association_name.to_s.singularize}_fields", :locals => {:f => fields}) }
      @fields ||= {}
      @fields[association_name] = block
      super(association_name, *(args << block))
    end

    def fields_for_nested_model(name, object, options, block)
      @nested_wrapper_tag = options.delete(:wrapper_tag) || @nested_wrapper_tag || :div
      @nested_builder = (options[:builder] ||= @nested_builder)
      @template.content_tag  @nested_wrapper_tag, super, :class => 'fields'
    end
  end
end
