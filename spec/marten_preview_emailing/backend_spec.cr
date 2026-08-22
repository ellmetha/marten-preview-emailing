require "./spec_helper"

describe MartenPreviewEmailing::Backend do
  describe "#location" do
    it "defaults to tmp/emails relative to the compilation root path" do
      backend = MartenPreviewEmailing::Backend.new

      backend.location.should eq(
        Path[Marten::Apps::Config.compilation_root_path].join(MartenPreviewEmailing::DEFAULT_EMAILS_LOCATION)
      )
    end

    it "uses the specified path" do
      backend = MartenPreviewEmailing::Backend.new(Path["/tmp/custom-emails"])

      backend.location.should eq(Path["/tmp/custom-emails"])
    end

    it "resolves string locations relative to the compilation root path" do
      backend = MartenPreviewEmailing::Backend.new("tmp/custom-emails")

      backend.location.should eq(Path[Marten::Apps::Config.compilation_root_path].join("tmp/custom-emails"))
    end
  end

  describe "#deliver" do
    it "collects the given email as a preview email" do
      preview_backend.deliver(MartenPreviewEmailing::BackendSpec::TestEmail.new)

      preview_directory
    end
  end
end

module MartenPreviewEmailing::BackendSpec
  class TestEmail < Marten::Email
    subject "Hello World!"
    to "test@example.com"

    def html_body
      "HTML body"
    end

    def text_body
      "Text body"
    end
  end
end
