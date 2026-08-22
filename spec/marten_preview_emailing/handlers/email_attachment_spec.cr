require "./spec_helper"

describe MartenPreviewEmailing::EmailAttachmentHandler do
  describe "#get" do
    it "serves a collected attachment" do
      preview_backend.deliver(MartenPreviewEmailing::EmailAttachmentHandlerSpec::TestEmailWithAttachment.new)
      id = preview_directory.basename

      url = Marten.routes.reverse(
        "preview_emailing:attachment",
        id: id,
        filename: "test_attachment.txt"
      )
      response = Marten::Spec.client.get(url)

      response.status.should eq(200)
      response.content.should eq("Attachment content")
      response.content_type.should eq("text/plain")
    end

    it "returns a 404 response when the attachment does not exist" do
      preview_backend.deliver(MartenPreviewEmailing::EmailAttachmentHandlerSpec::TestEmail.new)
      id = preview_directory.basename

      url = Marten.routes.reverse(
        "preview_emailing:attachment",
        id: id,
        filename: "missing.txt"
      )

      expect_raises(Marten::HTTP::Errors::NotFound) do
        Marten::Spec.client.get(url)
      end
    end
  end
end

module MartenPreviewEmailing::EmailAttachmentHandlerSpec
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

  class TestEmailWithAttachment < TestEmail
    def initialize
      attach(IO::Memory.new("Attachment content"), filename: "test_attachment.txt")
    end
  end
end
