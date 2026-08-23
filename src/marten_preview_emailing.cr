require "file_utils"
require "html"
require "json"
require "mime"

require "./marten_preview_emailing/app"
require "./marten_preview_emailing/backend"
require "./marten_preview_emailing/handlers/*"
require "./marten_preview_emailing/preview_email"
require "./marten_preview_emailing/routes"

module MartenPreviewEmailing
  VERSION = "0.1.0"

  # Default directory where collected emails are stored, relative to the project root.
  DEFAULT_EMAILS_LOCATION = "tmp/emails"

  # Returns the directory where collected emails are stored.
  #
  # When the configured emailing backend is a `Backend`, its location is used. Otherwise emails are looked up under
  # `#DEFAULT_EMAILS_LOCATION` relative to the project root.
  def self.emails_location : Path
    backend = Marten.settings.emailing.backend
    if backend.is_a?(Backend)
      backend.location
    else
      Path[Marten::Apps::Config.compilation_root_path].join(DEFAULT_EMAILS_LOCATION)
    end
  end
end
