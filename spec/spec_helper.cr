ENV["MARTEN_ENV"] = "test"

require "spec"

require "file_utils"
require "marten"
require "marten/spec"

require "../src/marten_preview_emailing"

require "./test_project"

Spec.before_each do
  FileUtils.rm_rf(PREVIEW_EMAILS_LOCATION.to_s)
  Dir.mkdir_p(PREVIEW_EMAILS_LOCATION)
end

def preview_backend : MartenPreviewEmailing::Backend
  Marten.settings.emailing.backend.as(MartenPreviewEmailing::Backend)
end

def preview_directory : Path
  location = MartenPreviewEmailing.emails_location
  children = Dir.children(location.to_s)
  children.size.should eq(1)
  location.join(children[0])
end
