module MartenPreviewEmailing
  # Lists emails collected by the preview emailing backend.
  class EmailListHandler < Marten::Handlers::Template
    template_name "marten_preview_emailing/email_list.html"

    before_render :add_emails_to_context

    private def add_emails_to_context : Nil
      context[:emails] = PreviewEmail.all
    end
  end
end
