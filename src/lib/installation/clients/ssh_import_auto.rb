require "yast"

require "installation/auto_client"
require "installation/ssh_importer"

Yast.import "Progress"

module Installation
  # Autoyast client for ssh_import
  class SSHImportAutoClient < ::Installation::AutoClient
    class << self
      attr_accessor :changed
    end

    def run
      progress_orig = Yast::Progress.set(false)
      ret = super
      Yast::Progress.set(progress_orig)

      ret
    end

    def import(data)
      ::Installation::SshImporter.instance.import(data)
      true
    end

    def summary
      "<UL>" + ::Installation::SshImporter.instance.summaray + "</UL>"
    end

    def modified?
      self.class.changed
    end

    def modified
      self.class.changed = true
    end

    def reset
      ::Installation::SshImporter.instance.reset
    end

    def change
      begin
        Yast::Wizard.OpenAcceptDialog
        result = WFM.CallFunction("inst_ssh_import", [args])
      ensure
        Yast::Wizard.CloseDialog
      end
    end

    # Return configuration data
    #
    # return map
    def export
      ::Installation::SshImporter.instance.export
    end

    def write
      ::Installation::SshImporter.instance.write
    end

    def read
      # It is a user decision only. Not depending on system
      true
    end

  end
end
