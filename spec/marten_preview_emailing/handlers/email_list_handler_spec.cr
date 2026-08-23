require "./spec_helper"

describe MartenPreviewEmailing::EmailListHandler do
  describe "#get" do
    it "renders an empty state when no emails were collected" do
      url = Marten.routes.reverse("preview_emailing:list")
      response = Marten::Spec.client.get(url)

      response.status.should eq(200)
      response.content.should contain("No emails have been collected yet.")
    end

    it "lists collected emails" do
      preview_backend.deliver(MartenPreviewEmailing::EmailListHandlerSpec::TestEmail.new)
      id = preview_directory.basename

      url = Marten.routes.reverse("preview_emailing:list")
      response = Marten::Spec.client.get(url)

      response.status.should eq(200)
      response.content.should contain("Hello World!")
      response.content.should contain("test@example.com")
      response.content.should contain("webmaster@localhost")
      response.content.should contain("/emails/#{id}")
      response.content.should contain("Clear all")
      response.content.should contain("Delete")
    end
  end
end

module MartenPreviewEmailing::EmailListHandlerSpec
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
