module MartenPreviewEmailing
  # An emailing backend that stores emails locally so that they can be previewed in the browser later on.
  #
  # Each delivered email is written to a dedicated directory under `#location` as HTML files that can be inspected from
  # the preview handlers.
  #
  # ```
  # config.emailing.backend = MartenPreviewEmailing::Backend.new
  # ```
  #
  # Alternatively, a directory where emails are stored can be specified as a string, in which case it is relative to
  # the project root.
  #
  # ```
  # config.emailing.backend = MartenPreviewEmailing::Backend.new(MartenPreviewEmailing::DEFAULT_EMAILS_LOCATION)
  # ```
  class Backend < Marten::Emailing::Backend::Base
    # Returns the directory where email previews are stored.
    getter location : Path

    def initialize(@location : Path)
    end

    def initialize(location : String = DEFAULT_EMAILS_LOCATION)
      initialize(Path[Marten::Apps::Config.compilation_root_path].join(location))
    end

    # Collects the given email as a local HTML preview.
    def deliver(email : Marten::Emailing::Email) : Nil
      PreviewEmail.collect(email, email_directory)
    end

    private def email_directory : Path
      timestamp = Time.local.to_unix_f.to_s.gsub('.', '_')
      location.join("#{timestamp}_#{Random::Secure.hex(4)}")
    end
  end
end
