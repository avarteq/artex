require 'tempfile'

module RTex
  module Framework    
    module Rails
      
      def self.setup
        ActionView::Base.register_template_handler(:rtex, Template)  
        ActionController::Base.send(:include, ControllerMethods)
      end
      
      class Template < ::ActionView::TemplateHandlers::ERB
        def initialize(*args)
          super
          @view.template_format = :pdf
        end
      end
      
      module ControllerMethods
        
        def self.included(base)
          base.alias_method_chain :render, :rtex
        end
        
        def render_with_rtex(options=nil, *args, &block)
          result = render_without_rtex(options, *args, &block)
          if result.is_a?(String) && @template.template_format == :pdf
            ::RTex::Document.new(result, :processed => true).to_pdf do |filename|
              serve_file = Tempfile.new('rtex-pdf')
              FileUtils.mv filename, serve_file.path
              send_file serve_file.path,
                :disposition => "inline",
                :url_based_filename => true,
                :filename => (options[:filename] rescue nil),
                :type => "application/pdf",
                :length => File.size(serve_file.path)
              serve_file.close
            end
          else
            result
          end
        end
        
      end
      
    end
  end
end