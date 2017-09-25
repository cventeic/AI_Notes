require 'typogruby'
require 'prawn'

require 'yaml'
require 'forwardable'
require 'tmpdir'
require 'digest/sha1'
require 'yaml/store'

require 'json'

require 'pp'

# $LOAD_PATH << "#{Dir.home}/scripts/utility"
# require 'run_cmd'

require 'tempfile'
require 'json'

require 'kramdown/converter'

module Kramdown

  module Converter
    #
    # Execute code blocks
    #
    # This converter modifies the given tree in-place and returns it.
    #
    class ExecuteCode < Base

      def initialize(root, options)
        super
        @options[:template] = ''
      end

      # Determine if we should erase code block after executing
      def remove_after_execute (options)
        ial     = options.fetch(:ial, {})
        ial     = {} if ial.nil? # fix it if ial actually set to nil in element
        klass   = ial.fetch("class", "")

        return  klass.include?('execute_and_replace') ||
                klass.include?('remove')
      end

      def convert(el)
        children = el.children.dup
        index = 0
        while index < children.length

          child = children[index]

          if (
            (child.type == :codeblock) &&
            (child.options[:lang] == 'ruby')
          )
            # Execute the code block
            #
            file = Tempfile.new('foo')
            file.write(child.value)
            file.flush

            cmd = "rbenv exec ruby #{file.path}"
            # cmd_out = `#{cmd}`

            file.unlink

            children[index..index] = children[index].children if remove_after_execute(child.options)
          else
            convert(children[index])
            index += 1
          end

        end
        el.children = children
        el
      end
    end
  end
end



file = File.open(ARGV[0])

txt = file.read

doc = Kramdown::Document.new(txt, :template => 'document')

# ast = doc.to_hash_ast
# fo1 = File.open("hash_ast.txt", "w")
# fo1.write(ast)

doc.to_execute_code

latex = doc.to_latex
f_latex = File.open("#{ARGV[0]}.latex", "w")
f_latex.write(latex)

=begin
pdf = doc.to_pdf
f_pdf = File.open("out.pdf", "w")
f_pdf.write(pdf)

html  = doc.to_html
# html2 = Typogruby.improve(html)
f_html = File.open("one.html", "w")
f_html.write(html)
=end

