require "./spec_helper"

describe MartenPreviewEmailing::PreviewEmail::Meta do
  describe ".from_json" do
    it "deserializes persisted metadata" do
      preview_backend.deliver(MartenPreviewEmailing::PreviewEmail::MetaSpec::TestEmail.new)

      directory = preview_directory
      meta = MartenPreviewEmailing::PreviewEmail::Meta.from_json(File.read(directory.join("meta.json")))

      meta.subject.should eq("Hello World!")
      meta.to.should eq("test@example.com")
      meta.has_html?.should be_true
      meta.has_text?.should be_true
    end
  end
end

module MartenPreviewEmailing::PreviewEmail::MetaSpec
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
