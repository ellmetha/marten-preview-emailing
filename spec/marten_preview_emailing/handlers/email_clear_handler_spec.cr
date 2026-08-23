require "./spec_helper"

describe MartenPreviewEmailing::EmailClearHandler do
  describe "#post" do
    it "deletes all collected emails and redirects to the list" do
      preview_backend.deliver(MartenPreviewEmailing::EmailClearHandlerSpec::TestEmail.new)
      preview_backend.deliver(MartenPreviewEmailing::EmailClearHandlerSpec::TestEmail.new)

      url = Marten.routes.reverse("preview_emailing:clear")
      response = Marten::Spec.client.post(url)

      response.status.should eq(302)
      response.headers["Location"].should eq("/emails")
      MartenPreviewEmailing::PreviewEmail.all.should be_empty
    end

    it "redirects to the list when no emails were collected" do
      url = Marten.routes.reverse("preview_emailing:clear")
      response = Marten::Spec.client.post(url)

      response.status.should eq(302)
      response.headers["Location"].should eq("/emails")
    end
  end
end

module MartenPreviewEmailing::EmailClearHandlerSpec
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
