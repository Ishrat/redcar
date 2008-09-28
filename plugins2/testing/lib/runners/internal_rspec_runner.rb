
module Redcar::Testing
  class InternalRSpecRunner
    def self.spec_plugin(plugin_name)
      puts "speccing plugin name: #{plugin_name}"
      
      set_redcar_formatter

      spec_files(plugin_name).each do |spec_file|
        load spec_file
      end
      lookup_example_groups.each do |eg|
        eg.run
      end
      
      tab = Redcar.win.new_tab(Redcar::TestViewTab)
      tab.title = "RSpec Results"
      tab.document.text = prepare_results
      tab.modified = false
      tab.focus
      cleanup_rspec
    end

    def self.plugin_dir(plugin_name)
      plugin_slot = bus['/plugins/'+plugin_name]
      path = plugin_slot.data.plugin_configuration.require_path
      File.dirname(path)
    end

    def self.spec_files(plugin_name)
      spec_path = "#{Redcar.PLUGINS_PATH}/#{plugin_dir(plugin_name)}/spec"
      Dir["#{spec_path}/*_spec.rb"] + Dir["#{spec_path}/**/*_spec.rb"]
    end

    def self.lookup_example_groups
      cs = []
      lookup_example_groups1(Spec::Example::ExampleGroup, cs)
      cs
    end

    def self.lookup_example_groups1(const, cs)
      const.constants.sort.each do |c|
        if c =~ /Subclass_/
          subconst = const.const_get(c)
          if !cs.include?(subconst) and const != subconst
            cs << subconst
            lookup_example_groups1(subconst, cs)
          end
        end
      end
      cs
    end
    
    def self.set_redcar_formatter
      def rspec_options.formatters
        @redcar_formatter ||= Redcar::Testing::TabFormatter.new
        [@redcar_formatter]
      end
    end

    def self.prepare_results
      rspec_options.reporter.dump
      results = rspec_options.formatters.first.results
      text=<<-END
     
#{results[3]}
END
    end

    def self.clean_example_groups(groups)
      groups.sort_by{|c| c.to_s.length}.reverse.each do |c|
        Spec::Example::ExampleGroup.send(:remove_const, c.to_s.split("::").last.intern) rescue nil
      end
    end

    def self.cleanup_rspec
      clean_example_groups(lookup_example_groups)
      rspec_options.reporter.send(:clear)
      rspec_options.instance_variable_set(:@redcar_formatter, nil)
    end
  end
end