module Puppet
  newtype(:delete_line) do
    @doc = "Ensure that the given line is not defined in the file, and
            delete the line if it is."

    newparam(:name) do
      desc "The name of the resource"
    end

    newparam(:file) do
      desc "The file to examine (and possibly modify) for the line."
    end

    newparam(:line) do
      desc "The line we're interested in."
    end

    newproperty(:ensure) do
      desc "Whether the resource is in sync or not."

      defaultto :insync

      def retrieve
        File.readlines(resource[:file]).map { |l|
            l.chomp
        }.include?(resource[:line]) ? :outofsync : :insync
      end

      newvalue :outofsync
      newvalue :insync do
        text = File.read(resource[:file])
        text.gsub!(resource[:line],'')
        File.open(resource[:file], 'w') { |fd| fd.write(text) }
      end
    end
  end
end